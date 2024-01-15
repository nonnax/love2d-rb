#!/usr/bin/ruby -w

=begin
/***************************************************************************
 *   Copyright (C) 2008, Paul Lutus                                      *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/
=end

require 'gravity_ui'

PROGRAM_VERSION = "1.5"

# main class

class Gravity < GravityGlade

   Gravity::PlanetColors = [ Gdk::Color.parse("white"),Gdk::Color.parse("yellow"),
      Gdk::Color.parse("cyan"), Gdk::Color.new(128 * 256,128 * 256,255 * 256),
      Gdk::Color.parse("red"),Gdk::Color.parse("green"),
   Gdk::Color.parse("magenta"),Gdk::Color.parse("blue") ]

   Gravity::AnimStrings = [ "1 hour","2 hours","4 hours","8 hours","16 hours",
   "1 day","2 days","4 days","8 days","16 days","32 days","64 days","128 days","256 days" ]

   Gravity::CometStrings = [ "1","2","4","8","16","32","64","128","256","512" ]

   def initialize(path,xxx,name)
      super(path,xxx,name)
      get_widgets()
      @program_name = self.class.name
      @program_title = @program_name + " " + PROGRAM_VERSION
      GravityUI().set_title(@program_title)

      @total_time_hours = 0
      @initialized = false
      # this sets the sleep interval (units are seconds)
      @anim_time = 0.005
      @anim_thread = nil
      @anim_flag = false
      # initial drawing scale, change with mouse wheel
      @drawing_scale = 6e-12
      @rotx = -20
      @roty = 0
      @planet_list = []
      @time_step = nil
      @pixmap = nil
      @erase = true
      @anaglyph_mode = false
      @symmetric = false
      @nice = true
      @mouse_down = false

      @color_cyan = Gdk::Color.parse("cyan")
      @color_red = Gdk::Color.parse("red")
      @color_black = Gdk::Color.parse("black")
      @rotator = RotationMatrix.new
      @time_step_combobox_manager = ComboBoxManager.new(time_step_combobox(),AnimStrings,"16 hours")
      set_time_step(true)
      @comet_combobox_manager = ComboBoxManager.new(comet_combobox(),CometStrings,"16")
      solar_system_checkbutton.active = true
      comets_checkbutton.active = true
      # graphic_pane.signal_connect("expose_event") do
      #   draw_image
      # end
      @min_draw_radius = 5
      pixels_spinbutton.value = @min_draw_radius
      load_objects(true)
      @initialized = true
   end

   def get_widgets()
      @glade.widget_names.each do |name|
         # create accessor methods for each defined widget
         eval("def #{name}() return @glade.get_widget(\"#{name}\") end")
      end
   end

   def Gravity::message_dialog(window,message,inquiry = false)
      if inquiry
         dlg = Gtk::MessageDialog.new(nil,
         Gtk::MessageDialog::MODAL,
         Gtk::MessageDialog::QUESTION,
         Gtk::MessageDialog::BUTTONS_YES_NO,
         message)
      else # just an alert
         dlg = Gtk::MessageDialog.new(nil,
         Gtk::MessageDialog::MODAL,
         Gtk::MessageDialog::INFO,
         Gtk::MessageDialog::BUTTONS_OK,
         message)
      end
      dlg.set_title(window.class.name)
      response = dlg.run
      dlg.destroy
      return response == Gtk::MessageDialog::RESPONSE_YES || response == Gtk::MessageDialog::RESPONSE_OK
   end

   def close()
      Gtk.main_quit
   end


   def set_time_step(force = false)
      if(@initialized || force)
         s = @time_step_combobox_manager.active_string()
         v,units = s.split(" ")
         v = v.to_i
         v *= 3600 if units =~ /hour/i
         v *= 86400 if units =~ /day/i
         @time_step = v
      end
   end

   def show_status
      y = @total_time_hours
      h = y % 24
      y /= 24
      y *= 100
      d = (y % 36525) / 100
      y /= 36525
      str = sprintf("Elapsed time: %04dy %03dd %02dh",y,d,h)
      status_bar().text = str
   end

   def draw_planets(xsize,ysize,gc,anaglyph_flag = nil,td_color = nil)
      if(anaglyph_flag)
         gc.rgb_fg_color = td_color
      end
      i = 0
      @planet_list.each do |planet|
         v = planet.pos * @drawing_scale
         @rotator.rotate(v)
         @rotator.convert_3d_to_2d(v,anaglyph_flag)
         sxa = @x_screen_center + (v.x * @screen_scale)
         sya = @y_screen_center - (v.y * @screen_scale)
         if(sxa >= 0 && sxa < xsize && sya >= 0 && sya < ysize)
            # fake the sun's radius for aesthetics
            sr = (i == 0)?4e7:(planet.radius)
            s = Cart3.new(sr * @drawing_scale,0,-planet.pos.z * @drawing_scale);
            @rotator.convert_3d_to_2d(s)
            s.x *= @screen_scale * 100
            s.x = (s.x < @min_draw_radius)?@min_draw_radius:s.x
            sc = s.x/2
            unless(anaglyph_flag)
               col = PlanetColors[i % PlanetColors.size]
               gc.rgb_fg_color = col
            end
            @pixmap.draw_arc(gc,true,sxa-sc,sya-sc,s.x,s.x,0,23040)
         end
         i += 1
      end
   end

   def fill_block(gc,color,sx,sy,wx,wy)
      gc.fill = Gdk::GC::Fill::SOLID
      gc.rgb_fg_color = color
      @pixmap.draw_rectangle(gc,true,sx,sy,wx+2,wy+2)
   end

   def draw_image(erase = false)
      if(@initialized && @planet_list)
         show_status
         @rotator.populate_matrix(@rotx,@roty)
         alloc = graphic_pane().allocation
         xsize,ysize = alloc.width,alloc.height
         # create an off-screen pixmap for image drawing
         # whenever a change requires it
         if(@pixmap == nil || xsize != @old_xsize || ysize != @old_ysize)
            @pixmap = Gdk::Pixmap.new(graphic_pane().window,xsize,ysize,-1)
            @old_xsize = xsize
            @old_ysize = ysize
            @x_screen_center = xsize / 2
            @y_screen_center = ysize / 2
            @screen_scale = (@x_screen_center > @y_screen_center)?@y_screen_center:@x_screen_center

         end
         gc = Gdk::GC.new(@pixmap)
         # set image background to black
         fill_block(gc,@color_black,0,0,@old_xsize,@old_ysize) if @erase || erase
         if(@anaglyph_mode)
            # In 3D mode, let overlapping red & cyan lines appear white
            gc.function = Gdk::GC::OR
            # draw complete, rotated right-hand and left-hand
            # images in cyan and red for anaglyphic glasses
            draw_planets(xsize,ysize,gc,-1,@color_cyan) # right eye image
            draw_planets(xsize,ysize,gc,1,@color_red) # left eye image
            gc.function = Gdk::GC::COPY
         else
            # draw image once
            draw_planets(xsize,ysize,gc)
         end
         # pixpainter.end
         # move the completed image to the screen
         graphic_pane().window.draw_drawable(gc,@pixmap,0,0,0,0,@old_xsize,@old_ysize)
         @total_time_hours += @time_step / 3600
      end
   end

   def perform_orbit_calc
      OrbitalPhysics::process_planets(@planet_list,@time_step,@symmetric)
      draw_image
   end

   def toggle_animation
      if(@anim_flag)
         @anim_flag = false
         while(@anim_thread.alive?)
         end
      else
         @total_time_hours = 0
         @anim_flag = true
         @anim_thread = Thread.new {
            while @anim_flag
               # must have some thread "sleep" time
               # or GUI updates will stop
               sleep (@nice)?@anim_time:0.002
               perform_orbit_calc()
            end
         }
      end
      run_stop_button.label = ((@anim_thread == nil)?"Run":"Stop")
      draw_image(true)
   end

   def load_comets(force = false)
      if(@initialized || force)
         n = @comet_combobox_manager.active_string().to_i
         1.upto(n) do |i|
            name = "comet#{i}"
            ca = rand(360) # angle in x-z plane
            cr = rand(4e11) + 4e11 # distance from sun
            pos = Cart3.new(cr * Math.sin(ca * CommonCode::ToRad),0,cr * Math.cos(ca * CommonCode::ToRad))
            # comet initial velocity
            v = (rand(200) + 100) * 50.0
            v = (i % 2 == 1)?-v:v
            vel = Cart3.new(0,v,0)
            comet = Planet.new(name,1e3,pos,vel,1e9)
            @planet_list << comet
         end
      end
   end

   def load_orbital_data(data,sun_only = false)
      data = data.split("\n")
      data.shift # drop header line
      data.each do |line|
         fields = line.split(",")
         pos = Cart3.new(-fields[1].to_f,0,0)
         vel = Cart3.new(0,0,fields[4].to_f)
         planet = Planet.new(fields[0],fields[2].to_f,pos,vel,fields[3].to_f)
         @planet_list << planet
         break if sun_only
      end
   end

   def load_objects(force = false)
      @planet_list = []
      sun_only = !solar_system_checkbutton.active?
      load_orbital_data(SolarSystem::Data,sun_only)
      load_comets(force) if comets_checkbutton.active?
      draw_image(true)
   end

   def beep
      Gdk.beep
   end

   # close application cleanly

   def close(*x)
      Gtk.main_quit
   end

   # mouse events

   def mouseMoveEvent (e)
      if(@mouse_down)
         # rotate image by dragging mouse
         dx = (e.y - @mouse_press_x) / 2
         dy = (e.x - @mouse_press_y) / 2
         @rotx = @mouse_press_rx - dx
         @roty = @mouse_press_ry - dy
         draw_image(true)
      end
   end

   def mousePressEvent (e)
      # set up to control rotation
      # by dragging mouse
      @mouse_down = true
      @mouse_press_rx = @rotx
      @mouse_press_ry = @roty
      @mouse_press_x = e.y
      @mouse_press_y = e.x
      draw_image(true)
   end

   def mouseReleaseEvent (e)
      @mouse_down = false
      # set up to control rotation
      # by dragging mouse
      draw_image(true)
   end

   def wheelEvent (e)
      # change drawing scale using mouse wheel
      # get mouse wheel delta
      v = (e.direction == Gdk::EventScroll::DOWN)?-1:1
      v = v.to_f
      v = 1.0 + (v/10.0)
      @drawing_scale *= v
      draw_image(true)
   end

   # action handlers

   def on_GravityUI_delete_event(widget, arg0)
      close
   end

   def on_quit_button_clicked(widget)
      close
   end

   def on_run_stop_button_clicked(widget)
      toggle_animation
   end

   def on_eventbox1_button_press_event(widget, arg0)
      mousePressEvent(arg0)
   end

   def on_eventbox1_button_release_event(widget, arg0)
      mouseReleaseEvent(arg0)
   end

   def on_eventbox1_motion_notify_event(widget, arg0)
      mouseMoveEvent(arg0)
   end

   def on_eventbox1_scroll_event(widget, arg0)
      wheelEvent(arg0)
   end

   def on_time_step_combobox_changed(widget)
      set_time_step
   end
   def on_anaglyphic_checkbutton_toggled(widget)
      @anaglyph_mode = anaglyphic_checkbutton.active?
      draw_image(true)
   end
   def on_comet_combobox_changed(widget)
      comets_checkbutton.active = true
      load_objects
      draw_image(true)
   end
   def on_step_button_clicked(widget)
      toggle_animation if @anim_flag
      perform_orbit_calc
   end
   def on_pixels_spinbutton_value_changed(widget)
      @min_draw_radius = pixels_spinbutton.value
      draw_image(true)
   end
   def on_solar_system_checkbutton_toggled(widget)
      load_objects
   end
   def on_trails_checkbutton_toggled(widget)
      @erase = !trails_checkbutton.active?
   end

   def on_nice_checkbutton_toggled(widget)
      @nice = nice_checkbutton.active?
   end
   def on_comets_checkbutton_toggled(widget)
      load_objects
   end

   def on_graphic_pane_expose_event(widget, arg0)
      draw_image(true)
   end


end # class Gravity

class ComboBoxManager
   def initialize(box,list,default = nil)
      @box = box
      @hash = {}
      index = 0
      # a placeholder item is required to get around
      # a bug in the Glade designer that won't create
      # a sane combobox without it. So first,
      # remove the placeholder item
      @box.remove_text(0)
      list.each do |item|
         @box.append_text(item)
         @hash[item] = index
         index += 1
      end
      if (@hash[default])
         @box.set_active(@hash[default])
      else
         @box.set_active(0)
      end
   end
   def active_string()
      return @box.active_text
   end
end

# a class for routines and constants of common utility

class CommonCode
   CommonCode::ToRad = Math::PI / 180.0
   CommonCode::ToDeg = 180.0 / Math::PI
   def CommonCode::fmt_num(n)
      sprintf("%.2e",n)
   end
end

# solar system data class, all units mks

class SolarSystem
   SolarSystem::Data=<<-EOF
   "Name","OrbitRad","BodyRad","Mass","OrbitVel"
   "Sun",0,695000000,1.989E+030,0
   "Mercury",57900000000,2440000,3.33E+023,47900
   "Venus",108000000000,6050000,4.869E+024,35000
   "Earth",150000000000,6378140,5.976E+024,29800
   "Mars",227940000000,3397200,6.421E+023,24100
   "Jupiter",778330000000,71492000,1.9E+027,13100
   "Saturn",1429400000000,60268000,5.688E+026,9640
   "Uranus",2870990000000,25559000,8.686E+025,6810
   "Neptune",4504300000000,24746000,1.024E+026,5430
   "Pluto",5913520000000,1137000,1.27E+022,4740
   EOF
end

# a Cartesian 3D vector class
# with a number of important operator overrides

class Cart3
   attr_accessor :x,:y,:z
   def initialize(x = 0,y = 0,z = 0)
      if(x.class == self.class)
         @x = x.x
         @y = x.y
         @z = x.z
      else
         @x = x
         @y = y
         @z = z
      end
   end

   def -(e)
      Cart3.new(@x - e.x,@y - e.y,@z - e.z)
   end

   def +(e)
      Cart3.new(@x + e.x,@y + e.y,@z + e.z)
   end

   def *(e)
      if(e.class != self.class)
         # multiply by scalar
         Cart3.new(@x * e,@y * e,@z * e)
      else
         # multiply by vector
         Cart3.new(@x * e.x,@y * e.y,@z * e.z)
      end
   end

   def /(e)
      if(e.class != self.class)
         # divide by scalar
         Cart3.new(@x / e,@y / e,@z / e)
      else
         # divide by vector
         Cart3.new(@x / e.x,@y / e.y,@z / e.z)
      end
   end

   # sum of squares
   def sumsq
      @x*@x+@y*@y+@z*@z
   end

   def to_s
      "[#{CommonCode::fmt_num(@x)},#{CommonCode::fmt_num(@y)},#{CommonCode::fmt_num(@z)}]"
   end
end # class Cart3

=begin

Planet, a simple data class

name = string
radius = float
pos = Cart3
vel = Cart3
mass = float

=end

class Planet
   attr_accessor :name,:radius,:pos,:vel,:mass
   def initialize(name,radius,pos,vel,mass = 0)
      @name = name.gsub(/"/,"")
      @radius = radius
      @pos = pos
      @vel = vel
      @mass = mass
   end
   def to_s
      "#{@name},#{CommonCode::fmt_num(@radius)},#{@pos},#{@vel},#{CommonCode::fmt_num(@mass)}"
   end
end

# RotationMatrix performs 3D rotations and perspective

class RotationMatrix

   # perspective depth cue for 3D -> 2D transformation
   PerspectiveDepth = 16
   # empirical constant for anaglyphic rotation
   AnaglyphScale = 0.03

   RotationMatrix::ToRad = Math::PI / 180.0
   RotationMatrix::ToDeg = 180.0 / Math::PI

   # populate 3D matrix with values for x,y,z rotations

   def populate_matrix(xa,ya)

      # create trig values
      @sy = Math.sin(xa * RotationMatrix::ToRad);
      @cy = Math.cos(xa * RotationMatrix::ToRad);
      @sx = Math.sin(ya * RotationMatrix::ToRad);
      @cx = Math.cos(ya * RotationMatrix::ToRad);
   end

   # 3D -> 2D, add perspective cue,
   # perform anaglyph position change if specified

   def convert_3d_to_2d(v,anaglyph_flag = 0)
      v.x = (v.x * (PerspectiveDepth + v.z))/PerspectiveDepth
      v.x += v.z * anaglyph_flag * AnaglyphScale if anaglyph_flag
      v.y = (v.y * (PerspectiveDepth + v.z))/PerspectiveDepth
   end

   # rotate a 3D point using matrix values

   def rotate(v)
      # borrowed from my "Apple World" 1979
      hf = (v.x * @sx - v.z * @cx)
      py = v.y * @cy + @sy * hf
      px = v.x * @cx + v.z * @sx
      pz = -v.y * @sy + @cy * hf
      v.x = px; v.y = py; v.z = pz
   end
end # class RotationMatrix

=begin

Gravitational force f, Newtons, between two masses M and m:

f = G M m
   ------
    r^2

G = universal gravitational constant, 6.6742e-11 N m^2 / kg^2

M,m = masses of the two bodies, kilograms

r = radius (distance) between M and m, meters

acceleration, m/s, a for a force f and a mass m:

a = f/m

The shorthand version drops one of the masses
for a slight speed improvement, and goes
directly to acceleration a:

a = G M
   -----
    r^2

BUT the shorthand form assumes one
of the masses is infinite

In a numerical simulation using time slice dt:

velocity v += a * dt

position p += v * dt

All mks units

=end

class OrbitalPhysics

   # The all-important force of gravity

   OrbitalPhysics::G = 6.6742e-11 # N m^2 / kg^-2

   def OrbitalPhysics::compute_acceleration(pa,pb,dt)
      # don't compute self-gravitation
      if(pa != pb)
         radius = pa.pos - pb.pos
         sumsq = radius.sumsq
         hypot = Math.sqrt(sumsq)
         acc = -G * pb.mass / sumsq
         # this line assigns the acceleration to
         # the x,y,z velocity components along the
         # radius pa - pb without using trig functions
         pa.vel += radius / hypot * acc * dt
      end
   end

   def OrbitalPhysics::process_planets(planet_list,dt,symmetric = false)
      if(symmetric)
         # compute gravitation interactively for all bodies
         # very slow ... requires p^2 time
         planet_list.each do |p1|
            planet_list.each do |p2|
               compute_acceleration(p1,p2,dt)
            end
            p1.pos += p1.vel * dt
         end
      else
         # compute gravitation only wrt the sun
         # which is assumed to be first member of array
         sun = planet_list.first
         planet_list.each do |planet|
            compute_acceleration(planet,sun,dt)
            planet.pos += planet.vel * dt
         end
      end
   end

end # class OrbitalPhysics

# Main program
if __FILE__ == $0
   # Set values as your own application.
   PROG_PATH = "gravity.glade"
   PROG_NAME = "Gravity"
   Gravity.new(PROG_PATH, nil, PROG_NAME)
   Gtk.main
end
