#-
 - I2C driver written in Berry
 -
 - Support for TMP117 device
 -#

var SENSOR_ADDR = 0x48

class TMP117: Driver
  var wire            #- if wire == nil then the module is not initialized -#
  var temperature     # temperature result in °C
  var ready           # true if sensor is available and not busy

  def init()
    self.wire = tasmota.wire_scan(SENSOR_ADDR, 58)

    if self.wire
      #- write config Register / initialize Sensor -#
      print("I2C: TMP117 detected on bus "+str(self.wire.bus))
    end

    #- initialize sensor, if other mesurement method is required -#
  end

  #- returns the resolution temperature -#
  def read_temperature()
    if !self.wire return nil end  #- exit if not initialized -#

    #- sanity-check if sensor is accessible and ready
     - (check bus-acknowledge and ready-Flag) 
     -#
    self.ready = self.wire.write(SENSOR_ADDR, 0x00, 0x00, 1)
    if !self.ready return nil end  #- exit if not available -#
    
    # todo: read and check acknowledge-flag
    # if !self.ready return nil end  #- exit if not ready -#

    var b = self.wire.read_bytes(SENSOR_ADDR, 0x00, 2)
    var t = b.get(0,-2)

    # todo: check for 0x8000 initial value
    
    self.temperature = t*0.0078125
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
    var msg = string.format(
             "{s}TMP117 Temperatur{m}%.3f °C{e}",
              self.temperature)
    tasmota.web_send_decimal(msg)
  end

  #- add sensor value to teleperiod -#
  def json_append()
    if !self.wire return nil end  #- exit if not initialized -#
    import string
    var msg = string.format(",\"TMP117\":{\"Temperature\":%.3f}",
              self.temperature)
    tasmota.response_append(msg)
  end

end
tmp117 = TMP117()
tasmota.add_driver(tmp117)