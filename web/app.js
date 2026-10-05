/* S82 SIREN · NUI (HUD + menu + âm nút bấm) */
(() => {
    const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 's82_siren';
    const $ = (id) => document.getElementById(id);

    const hud = $('hud');
    const el = {
        lights: $('hud-lights'), siren: $('hud-siren'), tone: $('hud-tone'),
        aux: $('hud-aux'), auxTone: $('hud-aux-tone'), horn: $('hud-horn'), lock: $('hud-lock'),
        hint: $('move-hint'),
        menu: $('menu'), title: $('menu-title'), subtitle: $('menu-subtitle'), count: $('menu-count'),
        items: $('menu-items'), desc: $('menu-desc'),
    };

    const labels = { standby: 'Chờ' };
    let scale = 1.0;
    let moving = false;
    let player = null;

    const post = (name, data) => fetch(`https://${RES}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(() => {});

    const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

    /* ---------------- HUD ---------------- */
    function setItem(item, value) {
        switch (item) {
            case 'lights': el.lights.classList.toggle('on', !!value); break;
            case 'siren':  el.siren.classList.toggle('on', !!value); break;
            case 'tone':   el.tone.textContent = value ? value : labels.standby; break;
            case 'aux':
                el.aux.classList.toggle('on', !!value);
                el.auxTone.textContent = value ? value : '—';
                break;
            case 'horn':   el.horn.classList.toggle('on', !!value); break;
            case 'lock':   el.lock.classList.toggle('on', !!value); break;
        }
    }

    function setPosition(pos) {
        if (pos && typeof pos.x === 'number' && typeof pos.y === 'number') {
            hud.style.left = pos.x + '%';
            hud.style.top = pos.y + '%';
        } else {
            hud.style.left = '';
            hud.style.top = '';
        }
    }

    function savePosition() {
        const r = hud.getBoundingClientRect();
        const x = +(r.left / window.innerWidth * 100).toFixed(3);
        const y = +(r.top / window.innerHeight * 100).toFixed(3);
        moving = false;
        hud.classList.remove('moving');
        post('hud:savePosition', { x, y });
    }

    // Kéo thả
    let drag = null;
    hud.addEventListener('mousedown', (e) => {
        if (!moving || e.button !== 0) return;
        e.preventDefault();
        drag = { dx: e.clientX - hud.offsetLeft, dy: e.clientY - hud.offsetTop };
    });
    document.addEventListener('mousemove', (e) => {
        if (!drag) return;
        const maxX = window.innerWidth - 40, maxY = window.innerHeight - 40;
        hud.style.left = Math.min(Math.max(0, e.clientX - drag.dx), maxX) + 'px';
        hud.style.top = Math.min(Math.max(0, e.clientY - drag.dy), maxY) + 'px';
    });
    document.addEventListener('mouseup', () => { drag = null; });
    document.addEventListener('contextmenu', (e) => { if (moving) { e.preventDefault(); savePosition(); } });
    document.addEventListener('keyup', (e) => {
        if (moving && (e.key === 'Escape' || e.key === 'Enter' || e.key === 'Backspace' || e.key === ' ')) savePosition();
    });

    /* ---------------- ÂM THANH ---------------- */
    function playSound(file, volume) {
        try {
            if (player) player.pause();
            player = new Audio(`sounds/${file}.ogg`);
            player.volume = Math.max(0, Math.min(1, Number(volume) || 0));
            const p = player.play();
            if (p && p.catch) p.catch(() => { player = null; });
        } catch (_) { player = null; }
    }

    /* ---------------- MENU ---------------- */
    function renderItem(it, selected) {
        const cls = ['item'];
        if (it.type === 'separator') {
            return `<div class="item separator">${esc(it.label)}</div>`;
        }
        if (selected) cls.push('selected');
        if (it.disabled) cls.push('disabled');
        if (it.highlight) cls.push('highlight');

        let right = '';
        switch (it.type) {
            case 'list':
                right = `<span class="arrow">‹</span><span>${esc(it.option)}</span><span class="arrow">›</span>`;
                break;
            case 'checkbox':
                right = `<div class="toggle ${it.value ? 'on' : ''}"></div>`;
                break;
            case 'slider': {
                const pct = ((it.value - it.min) / Math.max(1, it.max - it.min)) * 100;
                right = `<div class="slider"><div style="width:${pct}%"></div></div><span class="slider-val">${esc(it.value)}${esc(it.suffix || '')}</span>`;
                break;
            }
            default:
                if (it.right) right = `<span>${esc(it.right)}</span>`;
                if (it.submenu) right += '<span class="chev">›</span>';
        }
        return `<div class="${cls.join(' ')}"><span class="label">${esc(it.label)}</span><span class="right">${right}</span></div>`;
    }

    function renderMenu(d) {
        el.title.textContent = d.title || 'S82 SIREN';
        el.subtitle.textContent = d.subtitle || '';
        const selectable = d.items.filter((i) => i.type !== 'separator');
        const pos = d.items.slice(0, d.index).filter((i) => i.type !== 'separator').length;
        el.count.textContent = selectable.length ? `${pos}/${selectable.length}` : '';
        el.items.innerHTML = d.items.map((it, i) => renderItem(it, i + 1 === d.index)).join('');
        el.desc.textContent = d.desc || '';

        const sel = el.items.children[d.index - 1];
        if (sel) {
            const top = sel.offsetTop - el.items.offsetTop;
            const view = el.items.clientHeight;
            if (top < el.items.scrollTop) el.items.scrollTop = top - 4;
            else if (top + sel.offsetHeight > el.items.scrollTop + view) el.items.scrollTop = top + sel.offsetHeight - view + 4;
        }
    }

    /* ---------------- NHẬN TỪ LUA ---------------- */
    window.addEventListener('message', (e) => {
        const d = e.data || {};
        switch (d.action) {
            case 'init':
                Object.assign(labels, d.labels || {});
                document.querySelectorAll('[data-label]').forEach((n) => {
                    const k = n.getAttribute('data-label');
                    if (labels[k]) n.textContent = labels[k];
                });
                if (labels.keys) document.querySelector('.menu-keys').textContent = labels.keys;
                el.tone.textContent = labels.standby;
                break;
            case 'hud:visible': hud.classList.toggle('hidden', !d.visible && !moving); break;
            case 'hud:item': setItem(d.item, d.value); break;
            case 'hud:scale':
                scale = d.scale || 1;
                hud.style.transform = `scale(${scale})`;
                break;
            case 'hud:position': setPosition(d.pos); break;
            case 'hud:lit': hud.classList.toggle('lit', !!d.lit); break;
            case 'hud:move':
                moving = !!d.state;
                hud.classList.toggle('moving', moving);
                if (moving) hud.classList.remove('hidden');
                el.hint.textContent = d.hint || '';
                break;
            case 'audio': playSound(d.file, d.volume); break;
            case 'menu:open': el.menu.classList.remove('hidden'); break;
            case 'menu:close': el.menu.classList.add('hidden'); break;
            case 'menu:render': renderMenu(d); break;
        }
    });
})();
