<script setup lang="ts">
import { ref, computed } from 'vue';
import RoomCard from './components/RoomCard.vue';
import { rooms as initialRooms } from './data/rooms';
const rooms = ref(initialRooms);
const searchTerm = ref('');
const filteredRooms = computed(() =>
  rooms.value.filter(r => r.name.toLowerCase().includes(searchTerm.value.toLowerCase()))
);
function onToggleFavorite(id: number) {
  const room = rooms.value.find(r => r.id === id);
  if (room) room.isFavorite = !room.isFavorite;
}
</script>
<template>
  <header>
    <h1>🏫 Smart Campus Dashboard</h1>
    <input v-model="searchTerm" placeholder="Rechercher une salle..." />
  </header>
  <main class="card-grid">
    <RoomCard
      v-for="room in filteredRooms"
      :key="room.id"
      :room="room"
      @toggle-favorite="onToggleFavorite"
    />
  </main>
</template>
