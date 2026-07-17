import 'models/report.dart';

final List<Report> dummyReports = [
  Report(
    id: 'REP-001',
    title: 'Proyector sin imagen',
    area: ReportArea.sistema,
    classroom: 'A-101',
    building: 'Edificio A',
    dateTime: DateTime(2026, 6, 25, 8, 30),
    details: 'El proyector del aula no muestra imagen.',
    status: ReportStatus.pendiente,
    reportedBy: 'Juan Pérez',
  ),

  Report(
    id: 'REP-002',
    title: 'Basura acumulada',
    area: ReportArea.limpieza,
    classroom: 'Pasillo',
    building: 'Edificio B',
    dateTime: DateTime(2026, 6, 25, 9, 15),
    details: 'Hay bolsas de basura acumuladas en el pasillo.',
    status: ReportStatus.enProceso,
    reportedBy: 'María López',
  ),

  Report(
    id: 'REP-003',
    title: 'Silla rota',
    area: ReportArea.mantenimiento,
    classroom: 'C-203',
    building: 'Edificio C',
    dateTime: DateTime(2026, 6, 24, 11, 45),
    details: 'Una silla tiene una pata quebrada.',
    status: ReportStatus.resuelto,
    reportedBy: 'Carlos Ramírez',
  ),

  Report(
    id: 'REP-004',
    title: 'Cable HDMI dañado',
    area: ReportArea.sistema,
    classroom: 'Laboratorio 2',
    building: 'Edificio D',
    dateTime: DateTime(2026, 6, 23, 10, 10),
    details: 'El cable HDMI no transmite señal.',
    status: ReportStatus.pendiente,
    reportedBy: 'Ana Torres',
  ),

  Report(
    id: 'REP-005',
    title: 'Puerta no cierra',
    area: ReportArea.mantenimiento,
    classroom: 'A-205',
    building: 'Edificio A',
    dateTime: DateTime(2026, 6, 22, 14, 30),
    details: 'La puerta principal del aula queda abierta.',
    status: ReportStatus.enProceso,
    reportedBy: 'Luis Gómez',
  ),

  Report(
    id: 'REP-006',
    title: 'Piso sucio',
    area: ReportArea.limpieza,
    classroom: 'B-104',
    building: 'Edificio B',
    dateTime: DateTime(2026, 6, 21, 8, 00),
    details: 'El piso requiere limpieza.',
    status: ReportStatus.resuelto,
    reportedBy: 'Fernanda Ruiz',
  ),
];