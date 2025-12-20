<script setup>
import { ref, onMounted, computed } from 'vue';
import Header from './components/Header.vue';
import Hero from './components/Hero.vue';
import CategoryRow from './components/CategoryRow.vue';
import VideoModal from './components/VideoModal.vue';
import VideoPlayer from './components/VideoPlayer.vue';

const library = ref([]);
const loading = ref(true);
const error = ref(null);
const selectedVideo = ref(null);
const playingVideo = ref(null);
const activeFilter = ref(null);

const filteredLibrary = computed(() => {
    if (!activeFilter.value) return library.value;
    return library.value.filter(cat => cat.name === activeFilter.value);
});

const featuredVideo = computed(() => {
    const source = filteredLibrary.value.length > 0 ? filteredLibrary.value : library.value;
    for (const category of source) {
        for (const genre of category.genres) {
            if (genre.videos.length > 0) {
                return { 
                    ...genre.videos[0], 
                    category: category.name, 
                    genre: genre.name 
                };
            }
        }
    }
    return null;
});

function setFilter(filter) {
    activeFilter.value = filter;
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

async function fetchLibrary() {
    try {
        const res = await fetch('/api/categories');
        if (!res.ok) throw new Error('Failed to load library');
        library.value = await res.json();
    } catch (e) {
        error.value = e.message;
    } finally {
        loading.value = false;
    }
}

function showDetails(video, category, genre) {
    selectedVideo.value = { video, category, genre };
}

function closeModal() {
    selectedVideo.value = null;
}

function playVideo(video) {
    selectedVideo.value = null;
    playingVideo.value = video;
}

function closePlayer() {
    playingVideo.value = null;
}

onMounted(fetchLibrary);
</script>

<template>
    <div class="app">
        <Header 
            :categories="library" 
            :activeFilter="activeFilter"
            @filter="setFilter"
        />
        
        <main>
            <div v-if="loading" class="loading">
                <div class="spinner"></div>
                <p>Loading library...</p>
            </div>
            
            <div v-else-if="error" class="error">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M12 8v4m0 4h.01"/>
                </svg>
                <p>{{ error }}</p>
                <button @click="fetchLibrary">Retry</button>
            </div>
            
            <template v-else>
                <Hero 
                    v-if="featuredVideo" 
                    :video="featuredVideo"
                    @play="playVideo(featuredVideo)"
                    @info="showDetails(featuredVideo, featuredVideo.category, featuredVideo.genre)"
                />
                
                <div class="content">
                    <template v-for="category in filteredLibrary" :key="category.path">
                        <CategoryRow 
                            v-for="genre in category.genres"
                            :key="genre.path"
                            :title="`${category.name} - ${genre.name}`"
                            :videos="genre.videos"
                            :category="category.name"
                            :genre="genre.name"
                            @select="showDetails"
                        />
                    </template>
                </div>
                
                <div v-if="library.length === 0" class="empty">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                        <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                    <h2>No videos found</h2>
                    <p>Add videos to Videos/Categories/[Films|Series]/[Genre]/</p>
                </div>
            </template>
        </main>
        
        <Transition name="fade">
            <VideoModal 
                v-if="selectedVideo"
                :video="selectedVideo.video"
                :category="selectedVideo.category"
                :genre="selectedVideo.genre"
                @close="closeModal"
                @play="playVideo"
            />
        </Transition>
        
        <Transition name="fade">
            <VideoPlayer 
                v-if="playingVideo"
                :video="playingVideo"
                @close="closePlayer"
            />
        </Transition>
    </div>
</template>

<style scoped>
.app {
    min-height: 100vh;
}

main {
    min-height: 100vh;
}

.content {
    position: relative;
    margin-top: -120px;
    padding: 0 0 60px;
    z-index: 10;
}

.loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100vh;
    gap: 20px;
}

.spinner {
    width: 48px;
    height: 48px;
    border: 3px solid var(--bg-hover);
    border-top-color: var(--accent);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

.loading p {
    color: var(--text-secondary);
    font-size: 1.1rem;
}

.error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100vh;
    gap: 16px;
}

.error svg {
    width: 64px;
    height: 64px;
    color: var(--accent);
}

.error p {
    color: var(--text-secondary);
    font-size: 1.1rem;
}

.error button {
    margin-top: 12px;
    padding: 12px 32px;
    background: var(--accent);
    color: white;
    font-size: 1rem;
    font-weight: 600;
    border-radius: 4px;
    transition: background var(--transition);
}

.error button:hover {
    background: var(--accent-hover);
}

.empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 60vh;
    gap: 16px;
    text-align: center;
}

.empty svg {
    width: 80px;
    height: 80px;
    color: var(--text-muted);
}

.empty h2 {
    font-size: 1.5rem;
    font-weight: 600;
}

.empty p {
    color: var(--text-secondary);
}

.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>
