PlantUML class diagram for ADS Appointment System

This folder contains a PlantUML file `diagram.puml` describing the domain model for
an appointment booking system used by an Office Manager, Dentists and Patients.

How to render
- Using Homebrew on macOS (recommended):
  1. brew install plantuml
  2. plantuml diagram.puml

- Using the PlantUML jar:
  1. Download plantuml.jar from https://plantuml.com/download
  2. java -jar plantuml.jar diagram.puml

What the diagram contains
- Classes: OfficeManager, UserAccount, Dentist, Patient, Surgery, Appointment,
  AppointmentRequest, Bill
- Associations capture who books appointments, where appointments are held and
  which patients/dentists participate.

Requirements mapping
- Register Dentists: `Dentist` class with dentistId and contact/specialization fields.
- Enroll Patients: `Patient` class with personal/contact/address/dateOfBirth fields.
- Appointment requests: `AppointmentRequest` captures patient-initiated requests (phone or web).
- Booking & confirmation: `OfficeManager` creates `Appointment` and `Appointment.confirm()` represents notification.
- View appointments: `Dentist.viewAppointments()` and `Patient` can view their appointments via associations.
- Surgery info: `Surgery` class stores name, address and phone.
- Cancellation/changes: `Patient.cancelAppointment()` and `Appointment.cancel()`.
- Business rules: Notes show constraints:
  - Dentist max 5 appointments per week
  - Patients with unpaid `Bill` cannot request new appointments

If you want, I can also:
- Generate a PNG/SVG of the diagram here
- Expand the model with sequence diagrams for booking and cancellation flows
