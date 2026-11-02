/*
 * Calibration Logger (50 Hz, 60 s)
 * Measurement Systems Lab, Session 06 - University of Tehran
 *
 * Wiring (calibration stage, no amplifier yet):
 *   5V --[10k]--+--[NTC thermistor]-- GND
 *               |
 *               +--> A0
 *
 * Samples A0 every 20 ms for 60 s and streams CSV over serial:
 *   t_s, adc, volt_V, R_therm_Ohm
 * then stops. Opening the serial port (e.g. from the MATLAB script)
 * resets the Uno, which starts a fresh 60 s log.
 */

const int           THERM_PIN   = A0;
const float         VREF        = 5.0f;      // default ADC reference (5 V rail)
const float         R_FIXED     = 10000.0f;  // series resistor on the 5 V side
const unsigned long DURATION_MS = 60000UL;   // 60 s record
const unsigned long Ts_ms       = 20UL;      // 20 ms -> 50 Hz

void setup() {
  Serial.begin(115200);
  Serial.println("t_s,adc,volt_V,R_therm_Ohm");
}

void loop() {
  static bool done = false;
  if (done) return;

  unsigned long t0   = millis();
  unsigned long next = t0;

  while (millis() - t0 < DURATION_MS) {
    if (millis() >= next) {
      next += Ts_ms;
      float t_s = (millis() - t0) / 1000.0f;
      int   adc = analogRead(THERM_PIN);
      float v   = adc * VREF / 1023.0f;

      // Divider inversion (thermistor on the GND side): R = R1 * V / (Vcc - V)
      float Rth = (v > 0.01f && v < VREF - 0.01f)
                    ? R_FIXED * v / (VREF - v)
                    : 0.0f;

      Serial.print(t_s, 4); Serial.print(",");
      Serial.print(adc);    Serial.print(",");
      Serial.print(v, 6);   Serial.print(",");
      Serial.println(Rth, 2);
    }
  }
  done = true;
}
