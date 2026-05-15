export interface Room {
  id: number;
  name: string;
  building: string;
  capacity: number;
  occupancy: number;
  equipment: string[];
  isFavorite: boolean;
}export const rooms: Room[] = [
  { id: 1, name: 'Amphi Galois', building: '510', capacity: 80, occupancy: 60, equipment: ['Projecteur', 'Tableau'], isFavorite: true },
  { id: 2, name: 'Salle 101', building: '620', capacity: 30, occupancy: 25, equipment: ['Projecteur'], isFavorite: false },
  { id: 3, name: 'Amphi Hadamard', building: '510', capacity: 120, occupancy: 100, equipment: ['Projecteur', 'Tableau'], isFavorite: true },
  { id: 4, name: 'Salle TP Info A', building: '650', capacity: 24, occupancy: 20, equipment: ['Ordinateurs'], isFavorite: false },
  { id: 5, name: 'Salle Conférence', building: '510', capacity: 50, occupancy: 40, equipment: ['Projecteur', 'Tableau'], isFavorite: true }
];
