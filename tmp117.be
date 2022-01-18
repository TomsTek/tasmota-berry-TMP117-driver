#-
 - I2C driver written in Berry
 -
 - Support for TMP117 device
 -#

class TMP117: Driver
  static sensor_name = "TMP117"       # sensor name
  static sensor_addr = 0x48           # I2C bus address for sensor
  static temp_label  = "Temperature"  # label for temperature in language of preference

  var wire            #- if wire == nil then the module is not initialized -#
  var temperature     # temperature result in °C
  var ready           # true if sensor is available and not busy
  var temp_format     # function to convert temperature to formatted string
  var tempres         # number of decimals from Tasmota settings
  var tempoffset      # temperature offset config, from Tasmota settings

  def init()
    self.wire = tasmota.wire_scan(self.sensor_addr, 58)
    if self.wire
      #- write config Register / initialize Sensor -#
      print("I2C: "..self.sensor_name.." detected on bus "+str(self.wire.bus))
    end
    self.tempres    = 2
    self.tempoffset = 0
    self.create_formatter()
    tasmota.add_rule("TempRes",    / value -> self.create_formatter(value))
    tasmota.add_rule("TempOffset", / value -> self.create_formatter(nil, value))
    tasmota.add_rule("SetOption8", / value -> self.create_formatter())
    tasmota.cmd("Backlog TempRes; TempOffset")
    #- initialize sensor, if other measurement method is required -#
  end

  def create_formatter(tempres,tempoffset)
    if tempres    != nil self.tempres    = tempres    end
    if tempoffset != nil self.tempoffset = tempoffset end
    var fahrenheit = tasmota.get_option(8) == 1
    print(self.sensor_name, "TempRes:"..self.tempres, "TempOffset:"..self.tempoffset, "Fahrenheit:"..fahrenheit)
    var tempmask = "%." .. self.tempres .. "f"
    self.temp_format = 
      def (temperature, display) 
        import string
        return string.format(
          tempmask .. (display ? " °" .. (fahrenheit ? "F" : "C") : ""), 
          (fahrenheit ? temperature * 1.8 + 32 : temperature) + self.tempoffset)
      end
  end

  #- returns the resolution temperature -#
  def read_temperature()
    if !self.wire return nil end  #- exit if not initialized -#

    #- sanity-check if sensor is accessible and ready
     - (check bus-acknowledge and ready-Flag) 
     -#
    self.ready = self.wire.write(self.sensor_addr, 0x00, 0x00, 1)
    if !self.ready return nil end  #- exit if not available -#
    
    # todo: read and check acknowledge-flag
    # if !self.ready return nil end  #- exit if not ready -#

    var b = self.wire.read_bytes(self.sensor_addr, 0x00, 2)
    var t = b.get(0,-2)

    # todo: check for 0x8000 initial value
    
    self.temperature = real(t)/128
    return self.temperature
  end


  #- trigger a read every second -#
  def every_second()
    if !self.wire return nil end  #- exit if not initialized -#
    self.read_temperature()
  end

  #- display sensor value in the web UI -#
  def web_sensor()
    if !self.wire return nil end  #- exit if not initialized -#
    import string
    var msg = string.format("{s}%s %s{m}%s{e}",
              self.sensor_name, self.temp_label, self.temp_format(self.temperature, true))
    tasmota.web_send_decimal(msg)
  end

  #- add sensor value to teleperiod -#
  def json_append()
    if !self.wire return nil end  #- exit if not initialized -#
    import string
    var msg = string.format(',"%s":{"%s":%s}',
              self.sensor_name, self.temp_label, self.temp_format(self.temperature, false))
    tasmota.response_append(msg)
  end

end
tmp117 = TMP117()
tasmota.add_driver(tmp117)
