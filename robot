const int trigPin1 = 8;
const int echoPin1 = 9;

const int trigPin2 = 11;
const int echoPin2 = 10;

const int trigPin3 = 12;
const int echoPin3 = 13;

// L293D Motor Driver Pins
const int ENA = 5;
const int IN1 = 2;
const int IN2 = 3;

const int ENB = 6;
const int IN3 = 4;
const int IN4 = 7;

// --- ADJUSTABLE PARAMETERS ---
const int baasKiirus = 160;       // Reduced base speed (range: 0-255)
const int laviDistants = 20;      // Distance threshold to trigger turns (cm)
const int ohtlikDistants = 8;     // Critical distance to trigger reverse backup (cm)


long Kaugust(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long kestus = pulseIn(echoPin, HIGH, 25000); // 25ms timeout

  if (kestus == 0) {
    return 999; // Return large value if out of range/timeout
  }

  return kestus * 0.034 / 2;
}


void vasakMootor(int kiirus) {
  kiirus = constrain(kiirus, -255, 255);

  if (kiirus > 0) {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
  } else if (kiirus < 0) {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
  } else {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
  }

  analogWrite(ENA, abs(kiirus));
}


void paremMootor(int kiirus) {
  kiirus = constrain(kiirus, -255, 255);

  if (kiirus > 0) {
    digitalWrite(IN3, HIGH);
    digitalWrite(IN4, LOW);
  } else if (kiirus < 0) {
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, HIGH);
  } else {
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
  }

  analogWrite(ENB, abs(kiirus));
}


void soida(int vasak, int parem) {
  vasakMootor(vasak);
  paremMootor(parem);
}


void peatu() {
  vasakMootor(0);
  paremMootor(0);
}


void setup() {
  pinMode(trigPin1, OUTPUT);
  pinMode(echoPin1, INPUT);

  pinMode(trigPin2, OUTPUT);
  pinMode(echoPin2, INPUT);

  pinMode(trigPin3, OUTPUT);
  pinMode(echoPin3, INPUT);

  pinMode(ENA, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  pinMode(ENB, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  Serial.begin(9600);

  peatu();
  delay(1000);
}


void loop() {
  long vasak = Kaugust(trigPin1, echoPin1);
  delay(15);

  long keskmine = Kaugust(trigPin2, echoPin2);
  delay(15);

  long parem = Kaugust(trigPin3, echoPin3);
  delay(15);

  Serial.print("Vasak: ");
  Serial.print(vasak);
  Serial.print(" cm | Keskmine: ");
  Serial.print(keskmine);
  Serial.print(" cm | Parem: ");
  Serial.print(parem);
  Serial.println(" cm");

  // 1. Emergency Reverse if stuck too close in front
  if (keskmine <= ohtlikDistants) {
    soida(-120, -120); // Back up
    delay(300);
    if (vasak > parem) {
      soida(-140, 140); // Turn left while backing up
    } else {
      soida(140, -140); // Turn right while backing up
    }
    delay(200);
  } 
  // 2. Obstacle in front: turn toward the side with more space
  else if (keskmine <= laviDistants) {
    if (vasak > parem) {
      soida(30, baasKiirus);  // Turn sharp left
    } else {
      soida(baasKiirus, 30);  // Turn sharp right
    }
  } 
  // 3. Obstacle detected on the left: steer right
  else if (vasak <= laviDistants) {
    soida(baasKiirus, 70);
  } 
  // 4. Obstacle detected on the right: steer left
  else if (parem <= laviDistants) {
    soida(70, baasKiirus);
  } 
  // 5. Clear path ahead: drive straight at lower base speed
  else {
    soida(baasKiirus, baasKiirus);
  }

  delay(20);
}
