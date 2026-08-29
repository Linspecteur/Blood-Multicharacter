let characters = [];
let maxSlots = 4;
let selectedSlot = null;
let canClose = false;
let isStaff = false;
let spawns = [];
let selectedSpawn = null;

$(document).ready(function() {
    // Listen for NUI Messages from Client
    window.addEventListener('message', function(event) {
        let data = event.data;
        
        if (data.action === "openUI") {
            characters = data.characters || [];
            maxSlots = data.maxSlots || 4;
            selectedSlot = null;
            canClose = data.canClose || false;
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
            // If slot is greater than allowed slots (maxSlots), it is locked
            if (i > maxSlots) {
                html += `
                    <div class="char-slot locked" data-slot="${i}">
                        <div class="slot-number">0${i}</div>
                        <div class="slot-details">
                            <span class="slot-title"><i class="fa-solid fa-lock"></i> RÉSERVÉ STAFF</span>
                            <span class="slot-subtitle">VIP EN DÉVELOPPEMENT</span>
                        </div>
                        <i class="fa-solid fa-shield-halved slot-indicator"></i>
                    </div>
                `;
                continue;
            }
            
            // Find if character exists for this slot
            let char = characters.find(c => c.slot === i);
            
            if (char) {
                let jobLabel = char.jobLabel || char.job || "Sans emploi";
                let gradeLabel = char.jobGradeLabel || char.job_grade || "";
                let subText = gradeLabel ? `${jobLabel} - ${gradeLabel}` : jobLabel;

                html += `
                    <div class="char-slot" data-slot="${i}" data-type="existing">
                        <div class="slot-number">0${i}</div>
                        <div class="slot-details">
                            <span class="slot-title">${char.firstname.toUpperCase()} ${char.lastname.toUpperCase()}</span>
                            <span class="slot-subtitle">${subText.toUpperCase()}</span>
                        </div>
                        <i class="fa-solid fa-chevron-right slot-indicator"></i>
                    </div>
                `;
            } else {
                html += `
                    <div class="char-slot empty" data-slot="${i}" data-type="empty">
                        <div class="slot-number">0${i}</div>
                        <div class="slot-details">
                            <span class="slot-title">EMPLACEMENT LIBRE</span>
                            <span class="slot-subtitle">DISPONIBLE</span>
                        </div>
                        <span class="slot-indicator-plus">+</span>
                    </div>
                `;
            }
        }
        
        $("#slots-container").html(html);
        
        // Slot Click Event
        $(".char-slot").click(function() {
            $(".char-slot").removeClass("active");
            $(this).addClass("active");
            
            if ($(this).hasClass("locked")) {
                selectedSlot = null;
                showPanel('locked');
                return;
            }
            
            selectedSlot = parseInt($(this).data("slot"));
            let type = $(this).data("type");
            
            if (type === "existing") {
                let char = characters.find(c => c.slot === selectedSlot);
                showCharacterInfo(char);
                // Tell client to preview this character ped with their skin/clothing
                $.post(`https://${GetParentResourceName()}/previewCharacter`, JSON.stringify({
                    charId: char.id || char.identifier,
                    skin: char.skin
                }));
            } else {
                showPanel('create');
                // Tell client to show default empty ped
                $.post(`https://${GetParentResourceName()}/previewEmpty`, JSON.stringify({
                    slot: selectedSlot
                }));
            }
        });
    }

    function showCharacterInfo(char) {
        $("#char-name").text(`${char.firstname} ${char.lastname}`);
        
        let jobLabel = char.jobLabel || char.job || "Chômeur";
        let gradeLabel = char.jobGradeLabel || char.job_grade || "";
        let fullJob = gradeLabel ? `${jobLabel} - ${gradeLabel}` : jobLabel;
        $("#char-job").text(fullJob.toUpperCase());
        
        let money = char.money !== undefined ? char.money : 0;
        let bank = char.bank !== undefined ? char.bank : 0;
        
        $("#char-cash").text(`${money.toLocaleString('fr-FR')} $`);
        $("#char-bank").text(`${bank.toLocaleString('fr-FR')} $`);
        $("#char-dob").text(char.dateofbirth);
        $("#char-gender").text(char.sex === 'f' ? 'FEMME' : 'HOMME');
        $("#char-playtime").text(char.playtime || "0 h");
        
        // Option 6: Enriched stats
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
