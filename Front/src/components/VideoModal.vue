<script setup>
import { computed, onMounted, onUnmounted } from 'vue';

const props = defineProps({
    video: Object,
    category: String,
    genre: String
});

const emit = defineEmits(['close', 'play']);

const thumbnailUrl = computed(() => `/api/thumbnail/${props.video.path}`);

const fileSize = computed(() => {
    const bytes = props.video.size;
    if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + ' GB';
    if (bytes >= 1048576) return (bytes / 1048576).toFixed(0) + ' MB';
    return (bytes / 1024).toFixed(0) + ' KB';
});

function handleKeydown(e) {
    if (e.key === 'Escape') emit('close');
}

onMounted(() => document.addEventListener('keydown', handleKeydown));
onUnmounted(() => document.removeEventListener('keydown', handleKeydown));
</script>

<template>
    <div class="modal-backdrop" @click.self="emit('close')">
        <div class="modal">
            <button class="close-btn" @click="emit('close')">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M18 6L6 18M6 6l12 12"/>
                </svg>
            </button>
            
            <div class="hero">
                <img :src="thumbnailUrl" :alt="video.name" />
                <div class="gradient"></div>
                <div class="hero-content">
                    <h1>{{ video.name }}</h1>
                    <div class="actions">
                        <button class="play" @click="emit('play', video)">
                            <svg viewBox="0 0 24 24" fill="currentColor">
                                <path d="M8 5v14l11-7z"/>
                            </svg>
                            Play
                        </button>
                    </div>
                </div>
            </div>
            
            <div class="details">
                <div class="meta">
                    <span class="badge">{{ category }}</span>
                    <span class="badge secondary">{{ genre }}</span>
                    <span class="size">{{ fileSize }}</span>
                </div>
                <p class="filename">{{ video.filename }}</p>
            </div>
        </div>
    </div>
</template>

<style scoped>
.modal-backdrop {
    position: fixed;
    inset: 0;
    z-index: 200;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(0,0,0,0.8);
    padding: 40px;
}

.modal {
    position: relative;
    width: 100%;
    max-width: 900px;
    background: var(--bg-secondary);
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,0.6);
}

.close-btn {
    position: absolute;
    top: 16px;
    right: 16px;
    z-index: 10;
    width: 36px;
    height: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--bg-primary);
    color: white;
    border-radius: 50%;
    transition: background var(--transition);
}

.close-btn:hover {
    background: var(--bg-hover);
}

.close-btn svg {
    width: 20px;
    height: 20px;
}

.hero {
    position: relative;
    aspect-ratio: 16/9;
}

.hero img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.hero .gradient {
    position: absolute;
    inset: 0;
    background: linear-gradient(to top, var(--bg-secondary) 0%, transparent 60%);
}

.hero-content {
    position: absolute;
    bottom: 24px;
    left: 24px;
    right: 24px;
}

.hero-content h1 {
    font-size: 2rem;
    font-weight: 700;
    margin-bottom: 16px;
    text-shadow: 0 2px 8px rgba(0,0,0,0.5);
}

.actions {
    display: flex;
    gap: 12px;
}

.play {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 24px;
    background: white;
    color: var(--bg-primary);
    font-size: 1rem;
    font-weight: 600;
    border-radius: 4px;
    transition: background var(--transition);
}

.play:hover {
    background: rgba(255,255,255,0.85);
}

.play svg {
    width: 20px;
    height: 20px;
}

.details {
    padding: 24px;
}

.meta {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 12px;
}

.badge {
    padding: 4px 10px;
    background: var(--accent);
    color: white;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    border-radius: 2px;
}

.badge.secondary {
    background: var(--bg-hover);
}

.size {
    color: var(--text-muted);
    font-size: 0.9rem;
}

.filename {
    color: var(--text-secondary);
    font-size: 0.9rem;
    word-break: break-all;
}
</style>
