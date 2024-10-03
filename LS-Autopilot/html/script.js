const resourceName = GetParentResourceName();

window.addEventListener('message', function(event) {
    if (event.data.type === 'open') {
        document.getElementById('autopilot-menu').style.display = 'block';
    } else if (event.data.type === 'close') {
        closeMenu();
    }
});

function updateSpeedLabel(value) {
    document.getElementById('speedValue').innerText = `${value} km/h`;
}

function startAutopilot() {
    const speed = document.getElementById('speed').value;
    $.post(`https://${resourceName}/startAutopilot`, JSON.stringify({ speed: speed }));
}

function stopAutopilot() {
    $.post(`https://${resourceName}/stopAutopilot`, JSON.stringify({}));
}

function closeMenu() {
    document.getElementById('autopilot-menu').style.display = 'none';
    $.post(`https://${resourceName}/closeMenu`, JSON.stringify({}));
}

document.onkeyup = function(data) {
    if (data.which == 27) {
        closeMenu();
    }
};
