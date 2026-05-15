<script setup lang="ts">
import { ref, computed } from 'vue'
import { rooms as initialRooms } from './data/rooms'

const rooms = ref(initialRooms)
const searchQuery = ref('')
const showFavoritesOnly = ref(false)

const filteredRooms = computed(() => {
  const query = searchQuery.value.toLowerCase()

  return rooms.value.filter(room => {
    const matchesSearch =
      !query ||
      room.name.toLowerCase().includes(query) ||
      room.building.toLowerCase().includes(query)
    const matchesFavorites = !showFavoritesOnly.value || room.isFavorite

    return matchesSearch && matchesFavorites
  })
})

function occupancyClass(room: Room) {
  if (room.occupancy === 0) {
    return 'is-free'
  } else if (room.occupancy < room.capacity * 0.8) {
    return 'is-partial'
  } else {
    return 'is-full'
  }
}

function toggleFavorite(roomId: number) {
  const room = rooms.value.find(r => r.id === roomId)
  if (room) {
    room.isFavorite = !room.isFavorite
  }
}

</script>


<template>
  <header>
    <h1>🏫 Smart Campus Dashboard</h1>
  </header>
  <main>
    <h2>Salles du campus</h2>
    <div class="search-bar">
      <input type="text" placeholder="Rechercher une salle..." v-model="searchQuery" />
      <button v-if="searchQuery" @click="searchQuery = ''">X</button>
    </div>
    <label>
      <input type="checkbox" v-model="showFavoritesOnly" />
      Afficher uniquement les favoris
    </label>
    <ul class="card-grid">
      <li v-for="room in filteredRooms" :key="room.id" :class="['room-card', occupancyClass(room)]" class="room-card">
        <h3>{{ room.name }}</h3>
        <p>Bâtiment {{ room.building }} · {{ room.capacity }} places</p>
        <p v-if="room.occupancy === 0" class="status-badge is-free">✅ Libre</p>
        <p v-else-if="room.occupancy < room.capacity * 0.8" class="status-badge is-partial">🟡 Partiellement occupée ({{ room.occupancy }}/{{ room.capacity }})</p>
        <p v-else class="status-badge is-full">🔴 Pleine ({{ room.occupancy }}/{{ room.capacity }})</p>
        <button class="fav-btn" @click="toggleFavorite(room.id)">
          <i :class="room.isFavorite ? 'fa-solid fa-heart' : 'fa-regular fa-heart'"></i>
        </button>
      </li>
    </ul>
  </main>
</template>
