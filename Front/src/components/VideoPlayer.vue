<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';

const props = defineProps({
    video: Object
});

const emit = defineEmits(['close']);

const videoRef = ref(null);
const playing = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const volume = ref(1);
const muted = ref(false);
const fullscreen = ref(false);
const showControls = ref(true);
const loading = ref(true);

let controlsTimeout = null;

const streamUrl = computed(() => `/api/stream/${props.video.path}`);

const progress = computed(() => 
    duration.value ? (currentTime.value / duration.value) * 100 : 0
);

const formattedTime = computed(() => {
    const format = (t) => {
        const h = Math.floor(t / 3600);
        const m = Math.floor((t % 3600) / 60);
        const s = Math.floor(t % 60);
        if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
        return `${m}:${s.toString().padStart(2, '0')}`;
    };
    return `${format(currentTime.value)} / ${format(duration.value)}`;
});

function togglePlay() {
    if (videoRef.value.paused) {
        videoRef.value.play();
    } else {
        videoRef.value.pause();
    }
}

function seek(e) {
    const rect = e.currentTarget.getBoundingClientRect();
    const percent = (e.clientX - rect.left) / rect.width;
    videoRef.value.currentTime = percent * duration.value;
}

function toggleMute() {
    muted.value = !muted.value;
    videoRef.value.muted = muted.value;
}

function setVolume(e) {
    const rect = e.currentTarget.getBoundingClientRect();
    volume.value = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
    videoRef.value.volume = volume.value;
    muted.value = volume.value === 0;
}

function toggleFullscreen() {
    if (document.fullscreenElement) {
        document.exitFullscreen();
    } else {
        document.documentElement.requestFullscreen();
    }
}

function handleMouseMove() {
    showControls.value = true;
    clearTimeout(controlsTimeout);
    controlsTimeout = setTimeout(() => {
        if (playing.value) showControls.value = false;
    }, 3000);
}

function handleKeydown(e) {
    if (e.key === 'Escape') {
        if (document.fullscreenElement) {
            document.exitFullscreen();
        } else {
            emit('close');
        }
    }
    if (e.key === ' ') {
        e.preventDefault();
        togglePlay();
    }
    if (e.key === 'ArrowLeft') {
        videoRef.value.currentTime -= 10;
    }
    if (e.key === 'ArrowRight') {
        videoRef.value.currentTime += 10;
    }
    if (e.key === 'f') {
        toggleFullscreen();
    }
    if (e.key === 'm') {
        toggleMute();
    }
}

function handleFullscreenChange() {
    fullscreen.value = !!document.fullscreenElement;
}

onMounted(() => {
    document.addEventListener('keydown', handleKeydown);
    document.addEventListener('fullscreenchange', handleFullscreenChange);
});

onUnmounted(() => {
    document.removeEventListener('keydown', handleKeydown);
    document.removeEventListener('fullscreenchange', handleFullscreenChange);
    clearTimeout(controlsTimeout);
});
</script>

<template>
    <div 
        class="player" 
        :class="{ 'hide-cursor': !showControls && playing }"
        @mousemove="handleMouseMove"
    >
        <video
            ref="videoRef"
            :src="streamUrl"
            autoplay
            @play="playing = true"
            @pause="playing = false"
            @timeupdate="currentTime = $event.target.currentTime"
            @durationchange="duration = $event.target.duration"
            @loadeddata="loading = false"
            @waiting="loading = true"
            @canplay="loading = false"
            @click="togglePlay"
        />
        
        <div v-if="loading" class="loader">
            <div class="spinner"></div>
        </div>
        
        <Transition name="fade">
            <div v-show="showControls" class="controls">
                <div class="top-bar">
                    <button class="back-btn" @click="emit('close')">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M19 12H5m7-7l-7 7 7 7"/>
                        </svg>
                    </button>
                    <h2>{{ video.name }}</h2>
                </div>
                
                <div class="bottom-bar">
                    <div class="progress-bar" @click="seek">
                        <div class="progress-bg"></div>
                        <div class="progress-fill" :style="{ width: progress + '%' }"></div>
                    </div>
                    
                    <div class="control-row">
                        <div class="left-controls">
                            <button @click="togglePlay">
                                <svg v-if="playing" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M6 4h4v16H6zm8 0h4v16h-4z"/>
                                </svg>
                                <svg v-else viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M8 5v14l11-7z"/>
                                </svg>
                            </button>
                            
                            <div class="volume-control">
                                <button @click="toggleMute">
                                    <svg v-if="muted || volume === 0" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51A8.796 8.796 0 0021 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06a8.99 8.99 0 003.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>
                                    </svg>
                                    <svg v-else-if="volume < 0.5" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M18.5 12A4.5 4.5 0 0016 7.97v8.05c1.48-.73 2.5-2.25 2.5-4.02zM5 9v6h4l5 5V4L9 9H5z"/>
                                    </svg>
                                    <svg v-else viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0014 7.97v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
                                    </svg>
                                </button>
                                <div class="volume-slider" @click="setVolume">
                                    <div class="volume-bg"></div>
                                    <div class="volume-fill" :style="{ width: (muted ? 0 : volume * 100) + '%' }"></div>
                                </div>
                            </div>
                            
                            <span class="time">{{ formattedTime }}</span>
                        </div>
                        
                        <div class="right-controls">
                            <button @click="toggleFullscreen">
                                <svg v-if="fullscreen" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/>
                                </svg>
                                <svg v-else viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/>
                                </svg>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </Transition>
    </div>
</template>

<style scoped>
.player {
    position: fixed;
    inset: 0;
    z-index: 300;
    background: black;
}

.player.hide-cursor {
    cursor: none;
}

video {
    width: 100%;
    height: 100%;
    object-fit: contain;
}

.loader {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(0,0,0,0.3);
}

.spinner {
    width: 60px;
    height: 60px;
    border: 4px solid rgba(255,255,255,0.2);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

.controls {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    background: linear-gradient(to bottom, rgba(0,0,0,0.7) 0%, transparent 30%, transparent 70%, rgba(0,0,0,0.9) 100%);
}

.top-bar {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 24px 32px;
}

.back-btn {
    width: 44px;
    height: 44px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(255,255,255,0.1);
    color: white;
    border-radius: 50%;
    transition: background var(--transition);
}

.back-btn:hover {
    background: rgba(255,255,255,0.2);
}

.back-btn svg {
    width: 24px;
    height: 24px;
}

.top-bar h2 {
    font-size: 1.3rem;
    font-weight: 600;
}

.bottom-bar {
    padding: 0 32px 24px;
}

.progress-bar {
    position: relative;
    height: 5px;
    cursor: pointer;
    margin-bottom: 16px;
}

.progress-bg {
    position: absolute;
    inset: 0;
    background: rgba(255,255,255,0.3);
    border-radius: 2px;
}

.progress-fill {
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    background: var(--accent);
    border-radius: 2px;
    transition: width 0.1s linear;
}

.progress-bar:hover .progress-bg,
.progress-bar:hover .progress-fill {
    height: 7px;
    top: -1px;
}

.control-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.left-controls,
.right-controls {
    display: flex;
    align-items: center;
    gap: 16px;
}

.control-row button {
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    border-radius: 4px;
    transition: background var(--transition);
}

.control-row button:hover {
    background: rgba(255,255,255,0.1);
}

.control-row button svg {
    width: 24px;
    height: 24px;
}

.volume-control {
    display: flex;
    align-items: center;
    gap: 8px;
}

.volume-slider {
    position: relative;
    width: 80px;
    height: 4px;
    cursor: pointer;
}

.volume-bg {
    position: absolute;
    inset: 0;
    background: rgba(255,255,255,0.3);
    border-radius: 2px;
}

.volume-fill {
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    background: white;
    border-radius: 2px;
}

.time {
    font-size: 0.9rem;
    color: var(--text-secondary);
    font-variant-numeric: tabular-nums;
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
