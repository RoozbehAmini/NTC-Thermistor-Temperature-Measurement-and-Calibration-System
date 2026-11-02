/*
 * Live Voltage Reader
 * Measurement Systems Lab, Session 06 - University of Tehran
 *
 * Used to set the two trimmer potentiometers:
 *   Pot 1 (diff-amp reference, target 3.730 V): wiper -> A2
 *   Pot 2 (ADC reference,      target 3.325 V): wiper -> A1
 * Change PIN_ANALOG to match the pot you are adjusting.
 *
 * Prints  Vout[V], R_pot[Ohm]  every 500 ms (2 Hz).
 *
 * Note: R_pot uses the divider formula R = R_FIXED * V / (Vcc - V), so it
 * is only meaningful when an unknown resistor sits under a 10k fixed
 * resistor (e.g. the thermistor divider). When setting a pot, read Vout only.
 */

const int   PIN_ANALOG = A2;       // A2 = pot 1, A1 = pot 2
const float VREF       = 5.0f;
const int   ADC_RES    = 1023;
const float R_FIXED    = 10000.0f;

void setup() {
  analogReference(DEFAULT);
  Serial.begin(9600);
  while (!Serial) { ; }
  Serial.println("Vout[V],R_pot[Ohm]");
}

void loop() {
  int   adc   = analogRead(PIN_ANALOG);
  float Vout  = (float)adc * VREF / (float)ADC_RES;
  float R_pot = -1.0f;                               // -1 = out of range
  if (Vout > 0.01f && Vout < VREF - 0.01f)           // avoid divide-by-zero at full scale
    R_pot = R_FIXED * (VREF / (VREF - Vout) - 1.0f);

  Serial.print(Vout, 4); Serial.print(",");
  Serial.println(R_pot, 2);
  delay(500);
}
