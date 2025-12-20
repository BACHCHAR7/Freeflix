<script setup>
import { ref } from 'vue';
import VideoCard from './VideoCard.vue';

const props = defineProps({
    title: String,
    videos: Array,
    category: String,
    genre: String
});

const emit = defineEmits(['select']);

const scrollContainer = ref(null);

function scroll(direction) {
    if (!scrollContainer.value) return;
    const amount = scrollContainer.value.clientWidth * 0.8;
    scrollContainer.value.scrollBy({
        left: direction === 'left' ? -amount : amount,
        behavior: 'smooth'
    });
}
</script>

<template>
    <section class="row">
        <h2>{{ title }}</h2>
        <div class="slider-container">
            <button class="nav-btn left" @click="scroll('left')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M15 18l-6-6 6-6"/>
                </svg>
            </button>
            
            <div class="slider" ref="scrollContainer">
                <VideoCard 
                    v-for="video in videos"
                    :key="video.path"
                    :video="video"
                    @click="emit('select', video, category, genre)"
                />
            </div>
            
            <button class="nav-btn right" @click="scroll('right')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 18l6-6-6-6"/>
                </svg>
            </button>
        </div>
    </section>
</template>

<style scoped>
.row {
    padding: 0 60px;
    margin-bottom: 40px;
}

h2 {
    font-size: 1.4rem;
    font-weight: 600;
    margin-bottom: 16px;
}

.slider-container {
    position: relative;
    margin: 0 -60px;
    padding: 0 60px;
}

.slider {
    display: flex;
    gap: 10px;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    scrollbar-width: none;
    padding: 10px 0;
}

.slider::-webkit-scrollbar {
    display: none;
}

.nav-btn {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    z-index: 10;
    width: 50px;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(0,0,0,0.5);
    color: white;
    opacity: 0;
    transition: opacity var(--transition);
}

.slider-container:hover .nav-btn {
    opacity: 1;
}

.nav-btn:hover {
    background: rgba(0,0,0,0.8);
}

.nav-btn svg {
    width: 32px;
    height: 32px;
}

.nav-btn.left {
    left: 0;
}

.nav-btn.right {
    right: 0;
}
</style>
