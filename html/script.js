let characters = [];
let slotConfigs = [];
let selectedSlot = null;
let canClose = false;
let isVIP = false;
let isStaff = false;
let spawns = [];
let selectedSpawn = null;

$(document).ready(function() {
    // Listen for NUI Messages from Client
    window.addEventListener('message', function(event) {
        let data = event.data;
        
        if (data.action === "openUI") {
            characters = data.characters || [];
            slotConfigs = data.slotConfigs || data.maxSlots || [];
            selectedSlot = null;
            canClose = data.canClose || false;
            isVIP = data.isVIP || false;
            isStaff = data.isStaff || false;
            spawns = data.spawns || [];
            
            renderSlots();
            showPanel('empty');
            
            // Set the online player count in the header
            $("#player-count").text(data.playerCount || 0);
            
            $("#app").fadeIn(300, function() {
                // Auto-select first existing character slot, or first empty slot
                let firstSlot = $(".char-slot[data-type='existing']").first();
                if (firstSlot.length === 0) {
                    firstSlot = $(".char-slot").first();
                }
                if (firstSlot.length > 0) {
                    firstSlot.click();
                }
            });
        } else if (data.action === "closeUI") {
            $("#app").fadeOut(300);
            $("#delete-modal").addClass("hidden");
        }
    });

    // Close or go back on Escape key
    $(document).keyup(function(e) {
        if (e.key === "Escape" || e.keyCode === 27) {
            // If delete modal is open, cancel it
            if (!$("#delete-modal").hasClass("hidden")) {
                $("#delete-modal").addClass("hidden");
                return;
            }
            // If register form is open, go back to create panel
            if ($("#register-content").hasClass("active")) {
                showPanel('create');
                return;
            }
            if ($("#spawn-content").hasClass("active")) {
                showPanel('info');
                return;
            }
            // Otherwise, if we can close the UI (player already loaded)
            if (canClose) {
                $.post(`https://${GetParentResourceName()}/closeUI`, JSON.stringify({}));
            }
        }
    });

    // Render Character Slots
    function renderSlots() {
        let html = '';
        
        for (let i = 1; i <= 4; i++) {
            let defaultType = (i === 4 ? 'staff' : ((i === 2 || i === 3) ? 'vip' : 'free'));
            let defaultLocked = (defaultType === 'staff' ? !isStaff : (defaultType === 'vip' ? (!isVIP && !isStaff) : false));
            let slotConf = slotConfigs.find(s => s.slot === i) || { slot: i, type: defaultType, isLocked: defaultLocked };
            let slotType = slotConf.type || defaultType;
            let isLocked = slotConf.isLocked;

            // Find if character exists for this slot
            let char = characters.find(c => c.slot === i);

            if (isLocked) {
                if (slotType === 'staff') {
                    html += `
                        <div class="char-slot locked slot-staff staff-locked" data-slot="${i}" data-slot-type="staff">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title"><i class="fa-solid fa-shield-halved"></i> EMPLACEMENT STAFF</span>
                                    <span class="slot-tag-badge staff-pill"><i class="fa-solid fa-shield"></i> STAFF</span>
                                </div>
                                <span class="slot-subtitle"><i class="fa-solid fa-lock"></i> RÉSERVÉ ADMINISTRATION</span>
                            </div>
                            <i class="fa-solid fa-lock slot-indicator"></i>
                        </div>
                    `;
                } else if (slotType === 'vip') {
                    html += `
                        <div class="char-slot locked slot-vip vip-locked" data-slot="${i}" data-slot-type="vip">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title"><i class="fa-solid fa-crown"></i> EMPLACEMENT VIP</span>
                                    <span class="slot-tag-badge vip-pill"><i class="fa-solid fa-crown"></i> VIP</span>
                                </div>
                                <span class="slot-subtitle"><i class="fa-solid fa-lock"></i> RÉSERVÉ VIP / DIAMOND</span>
                            </div>
                            <i class="fa-solid fa-lock slot-indicator"></i>
                        </div>
                    `;
                } else {
                    html += `
                        <div class="char-slot locked" data-slot="${i}" data-slot-type="free">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <span class="slot-title">EMPLACEMENT BLOQUÉ</span>
                                <span class="slot-subtitle">INDISPONIBLE</span>
                            </div>
                            <i class="fa-solid fa-lock slot-indicator"></i>
                        </div>
                    `;
                }
                continue;
            }

            // UNLOCKED STATE (with or without character)
            if (char) {
                let jobLabel = char.jobLabel || char.job || "Sans emploi";
                let gradeLabel = char.jobGradeLabel || char.job_grade || "";
                let subText = gradeLabel ? `${jobLabel} - ${gradeLabel}` : jobLabel;

                if (slotType === 'staff') {
                    html += `
                        <div class="char-slot slot-staff has-char" data-slot="${i}" data-type="existing" data-slot-type="staff">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title">${char.firstname.toUpperCase()} ${char.lastname.toUpperCase()}</span>
                                    <span class="slot-tag-badge staff-pill"><i class="fa-solid fa-shield-halved"></i> STAFF</span>
                                </div>
                                <span class="slot-subtitle">${subText.toUpperCase()} • EMPLACEMENT STAFF</span>
                            </div>
                            <i class="fa-solid fa-chevron-right slot-indicator"></i>
                        </div>
                    `;
                } else if (slotType === 'vip') {
                    html += `
                        <div class="char-slot slot-vip has-char" data-slot="${i}" data-type="existing" data-slot-type="vip">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title">${char.firstname.toUpperCase()} ${char.lastname.toUpperCase()}</span>
                                    <span class="slot-tag-badge vip-pill"><i class="fa-solid fa-crown"></i> VIP</span>
                                </div>
                                <span class="slot-subtitle">${subText.toUpperCase()} • EMPLACEMENT VIP</span>
                            </div>
                            <i class="fa-solid fa-chevron-right slot-indicator"></i>
                        </div>
                    `;
                } else {
                    html += `
                        <div class="char-slot slot-free has-char" data-slot="${i}" data-type="existing" data-slot-type="free">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title">${char.firstname.toUpperCase()} ${char.lastname.toUpperCase()}</span>
                                </div>
                                <span class="slot-subtitle">${subText.toUpperCase()}</span>
                            </div>
                            <i class="fa-solid fa-chevron-right slot-indicator"></i>
                        </div>
                    `;
                }
            } else {
                // UNLOCKED & EMPTY
                if (slotType === 'staff') {
                    html += `
                        <div class="char-slot empty slot-staff" data-slot="${i}" data-type="empty" data-slot-type="staff">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title"><i class="fa-solid fa-shield-halved"></i> EMPLACEMENT STAFF</span>
                                    <span class="slot-tag-badge staff-pill-unlocked"><i class="fa-solid fa-check"></i> STAFF DÉBLOQUÉ</span>
                                </div>
                                <span class="slot-subtitle">DISPONIBLE • PRIVILÈGE ADMINISTRATION</span>
                            </div>
                            <span class="slot-indicator-plus">+</span>
                        </div>
                    `;
                } else if (slotType === 'vip') {
                    html += `
                        <div class="char-slot empty slot-vip" data-slot="${i}" data-type="empty" data-slot-type="vip">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title"><i class="fa-solid fa-crown"></i> EMPLACEMENT VIP</span>
                                    <span class="slot-tag-badge vip-pill-unlocked"><i class="fa-solid fa-check"></i> VIP DÉBLOQUÉ</span>
                                </div>
                                <span class="slot-subtitle">DISPONIBLE • PRIVILÈGE VIP</span>
                            </div>
                            <span class="slot-indicator-plus">+</span>
                        </div>
                    `;
                } else {
                    html += `
                        <div class="char-slot empty slot-free" data-slot="${i}" data-type="empty" data-slot-type="free">
                            <div class="slot-number">0${i}</div>
                            <div class="slot-details">
                                <div class="slot-title-row">
                                    <span class="slot-title">EMPLACEMENT LIBRE</span>
                                </div>
                                <span class="slot-subtitle">DISPONIBLE (GRATUIT)</span>
                            </div>
                            <span class="slot-indicator-plus">+</span>
                        </div>
                    `;
                }
            }
        }
        
        $("#slots-container").html(html);
        
        // Slot Click Event
        $(".char-slot").click(function() {
            $(".char-slot").removeClass("active");
            $(this).addClass("active");
            
            let slotNum = parseInt($(this).data("slot"));
            let slotType = $(this).data("slot-type") || 'free';
            
            if ($(this).hasClass("locked")) {
                selectedSlot = null;
                showLockedInfo(slotType, slotNum);
                showPanel('locked');
                return;
            }
            
            selectedSlot = slotNum;
            let type = $(this).data("type");
            
            if (type === "existing") {
                let char = characters.find(c => c.slot === selectedSlot);
                showCharacterInfo(char, slotType);
                // Tell client to preview this character ped with their skin/clothing
                $.post(`https://${GetParentResourceName()}/previewCharacter`, JSON.stringify({
                    charId: char.id || char.identifier,
                    skin: char.skin
                }));
            } else {
                showCreatePrompt(slotType, selectedSlot);
                showPanel('create');
                // Tell client to show default empty ped
                $.post(`https://${GetParentResourceName()}/previewEmpty`, JSON.stringify({
                    slot: selectedSlot
                }));
            }
        });
    }

    function showLockedInfo(slotType, slotNum) {
        let card = $("#locked-content");
        card.removeClass("theme-vip theme-staff theme-free");
        
        if (slotType === 'staff') {
            card.addClass("theme-staff");
            $("#locked-icon").attr("class", "fa-solid fa-shield-halved staff-icon-glow");
            $("#locked-tier-pill").html('<i class="fa-solid fa-shield"></i> EMPLACEMENT 04 • PRIVILÈGE STAFF');
            $("#locked-title").text("ACCÈS STAFF RESTREINT");
            $("#locked-desc").text("Cet emplacement est strictement réservé aux membres du Staff et de l'Administration de BloodLeak RP.");
            $("#locked-card").html('<i class="fa-solid fa-user-shield"></i><span>Vérification automatique (bl_admin & table bl_staff)</span>');
        } else if (slotType === 'vip') {
            card.addClass("theme-vip");
            $("#locked-icon").attr("class", "fa-solid fa-crown vip-icon-glow");
            $("#locked-tier-pill").html(`<i class="fa-solid fa-gem"></i> EMPLACEMENT 0${slotNum} • PRIVILÈGE VIP`);
            $("#locked-title").text("EMPLACEMENT VIP");
            $("#locked-desc").text("Cet emplacement est réservé aux membres VIP, Donateurs et membres du Staff du serveur.");
            $("#locked-card").html('<i class="fa-solid fa-crown"></i><span>Vérification automatique de statut VIP / Donateur</span>');
        }
    }

    function showCreatePrompt(slotType, slotNum) {
        let createBlock = $("#create-content");
        createBlock.removeClass("theme-vip theme-staff theme-free");
        
        if (slotType === 'staff') {
            createBlock.addClass("theme-staff");
            $("#create-illustration").html('<i class="fa-solid fa-user-shield staff-icon-glow"></i>');
            $("#create-tier-badge").html('<span class="tier-pill staff-pill"><i class="fa-solid fa-shield-halved"></i> EMPLACEMENT STAFF 04 • ACTIF</span>');
            $("#create-title").text("NOUVEAU PERSONNAGE STAFF");
            $("#create-desc").text("Emplacement de citoyen débloqué via vos permissions d'administration.");
        } else if (slotType === 'vip') {
            createBlock.addClass("theme-vip");
            $("#create-illustration").html('<i class="fa-solid fa-crown vip-icon-glow"></i>');
            $("#create-tier-badge").html(`<span class="tier-pill vip-pill"><i class="fa-solid fa-crown"></i> EMPLACEMENT VIP 0${slotNum} • ACTIF</span>`);
            $("#create-title").text("NOUVEAU PERSONNAGE VIP");
            $("#create-desc").text("Emplacement de citoyen débloqué grâce à votre statut VIP / Donateur.");
        } else {
            createBlock.addClass("theme-free");
            $("#create-illustration").html('<i class="fa-solid fa-user-astronaut"></i>');
            $("#create-tier-badge").html('<span class="tier-pill free-pill"><i class="fa-solid fa-user"></i> EMPLACEMENT GRATUIT 01</span>');
            $("#create-title").text("NOUVEAU CITOYEN");
            $("#create-desc").text("Aucune donnée d'identité enregistrée sur cet emplacement de citoyen.");
        }
    }

    function showCharacterInfo(char, slotType) {
        $("#char-name").text(`${char.firstname} ${char.lastname}`);
        
        let jobLabel = char.jobLabel || char.job || "Chômeur";
        let gradeLabel = char.jobGradeLabel || char.job_grade || "";
        let fullJob = gradeLabel ? `${jobLabel} - ${gradeLabel}` : jobLabel;
        $("#char-job").text(fullJob.toUpperCase());
        
        if (slotType === 'staff') {
            $("#char-tier-badge").html('<span class="tier-pill staff-pill"><i class="fa-solid fa-shield-halved"></i> STAFF</span>');
        } else if (slotType === 'vip') {
            $("#char-tier-badge").html('<span class="tier-pill vip-pill"><i class="fa-solid fa-crown"></i> VIP</span>');
        } else {
            $("#char-tier-badge").html('<span class="tier-pill free-pill"><i class="fa-solid fa-user"></i> CITOYEN</span>');
        }
        
        let money = char.money !== undefined ? char.money : 0;
        let bank = char.bank !== undefined ? char.bank : 0;
        
        $("#char-cash").text(`${money.toLocaleString('fr-FR')} $`);
        $("#char-bank").text(`${bank.toLocaleString('fr-FR')} $`);
        $("#char-dob").text(char.dateofbirth);
        $("#char-gender").text(char.sex === 'f' ? 'FEMME' : 'HOMME');
        $("#char-playtime").text(char.playtime || "0 h");
        $("#char-phone").text(char.phone || "NON DÉFINI");
        
        showPanel('info');
    }

    function showPanel(type) {
        // Toggle active class for smooth CSS animation triggers
        $("#info-content").removeClass("active");
        $("#create-content").removeClass("active");
        $("#empty-selection").removeClass("active");
        $("#register-content").removeClass("active");
        $("#locked-content").removeClass("active");
        $("#spawn-content").removeClass("active");
        
        if (type === 'info') $("#info-content").addClass("active");
        else if (type === 'create') $("#create-content").addClass("active");
        else if (type === 'register') $("#register-content").addClass("active");
        else if (type === 'locked') $("#locked-content").addClass("active");
        else if (type === 'spawn') $("#spawn-content").addClass("active");
        else $("#empty-selection").addClass("active");
    }

    // Play Button opens the Spawn Selector panel
    $("#btn-play").click(function() {
        if (!selectedSlot) return;
        let char = characters.find(c => c.slot === selectedSlot);
        if (char) {
            renderSpawns();
            showPanel('spawn');
        }
    });

    function renderSpawns() {
        let html = '';
        spawns.forEach((spawn, index) => {
            let activeClass = index === 0 ? 'active' : '';
            if (index === 0) selectedSpawn = spawn;
            
            html += `
                <div class="spawn-item ${activeClass}" data-index="${index}">
                    <i class="${spawn.icon} spawn-icon"></i>
                    <div class="spawn-details">
                        <span class="spawn-title">${spawn.name}</span>
                        <span class="spawn-desc">${spawn.description}</span>
                    </div>
                </div>
            `;
        });
        $("#spawns-container").html(html);
        
        // Spawn item click listener
        $(".spawn-item").click(function() {
            $(".spawn-item").removeClass("active");
            $(this).addClass("active");
            let idx = parseInt($(this).data("index"));
            selectedSpawn = spawns[idx];
        });
    }

    $("#btn-confirm-spawn").click(function() {
        if (!selectedSlot || !selectedSpawn) return;
        let char = characters.find(c => c.slot === selectedSlot);
        if (char) {
            $.post(`https://${GetParentResourceName()}/playCharacter`, JSON.stringify({
                charId: char.id || char.identifier,
                spawnCoords: selectedSpawn.coords ? {
                    x: selectedSpawn.coords.x,
                    y: selectedSpawn.coords.y,
                    z: selectedSpawn.coords.z,
                    heading: selectedSpawn.heading || 0.0
                } : null
            }));
        }
    });

    $("#btn-cancel-spawn").click(function() {
        showPanel('info');
    });

    // Delete Button triggers modal
    $("#btn-delete").click(function() {
        $("#delete-modal").removeClass("hidden");
    });

    $("#btn-cancel-delete").click(function() {
        $("#delete-modal").addClass("hidden");
    });

    $("#btn-confirm-delete").click(function() {
        if (!selectedSlot) return;
        let char = characters.find(c => c.slot === selectedSlot);
        if (char) {
            $("#delete-modal").addClass("hidden");
            $.post(`https://${GetParentResourceName()}/deleteCharacter`, JSON.stringify({
                charId: char.id || char.identifier
            }));
        }
    });

    // Create Button triggers Registration inline panel
    $("#btn-create").click(function() {
        showPanel('register');
        $("#register-form")[0].reset();
    });

    // Auto-format DOB input with slashes (JJ/MM/AAAA)
    $("#reg-dob").on("input", function() {
        let val = $(this).val().replace(/\D/g, ""); // Keep only digits
        if (val.length > 8) {
            val = val.substring(0, 8);
        }
        
        let formatted = "";
        if (val.length > 0) {
            formatted += val.substring(0, 2);
        }
        if (val.length > 2) {
            formatted += "/" + val.substring(2, 4);
        }
        if (val.length > 4) {
            formatted += "/" + val.substring(4, 8);
        }
        
        $(this).val(formatted);
    });

    $("#btn-cancel-register").click(function() {
        showPanel('create');
    });

    // Submit Registration
    $("#register-form").submit(function(e) {
        e.preventDefault();
        
        let newChar = {
            slot: selectedSlot,
            firstname: $("#reg-firstname").val(),
            lastname: $("#reg-lastname").val(),
            dateofbirth: $("#reg-dob").val(),
            height: $("#reg-height").val(),
            sex: $("input[name='reg-gender']:checked").val()
        };
        
        $.post(`https://${GetParentResourceName()}/createCharacter`, JSON.stringify(newChar));
        
        // Hide UI immediately, client will restart process
        $("#app").fadeOut(200);
    });

    // Drag to rotate character
    let isDragging = false;
    let startX = 0;
    
    $(document).mousedown(function(e) {
        // Only rotate if clicked on the central empty area (not inside panels or modals)
        if (!$(e.target).closest(".sidebar-panel, .modal-box, .modal-overlay").length && $("#app").is(":visible")) {
            isDragging = true;
            startX = e.pageX;
        }
    });
    
    $(document).mousemove(function(e) {
        if (isDragging) {
            let currentX = e.pageX;
            let deltaX = currentX - startX;
            startX = currentX;
            
            $.post(`https://${GetParentResourceName()}/rotateCharacter`, JSON.stringify({
                delta: deltaX
            }));
        }
    });
    
    $(document).mouseup(function() {
        isDragging = false;
    });

});
