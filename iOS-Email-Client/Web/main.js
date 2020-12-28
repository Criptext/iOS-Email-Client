var richeditor = {};
var editor = document.getElementById("editor");

window.onload = function() {
    window.webkit.messageHandlers.documentHasLoaded.postMessage("ready");
};

richeditor.updatePlaceholder = function() {
    if (editor.innerHTML.indexOf('img') !== -1 || (editor.textContent.length > 0 && editor.innerHTML.length > 0)) {
        editor.classList.remove("placeholder");
    } else {
        editor.classList.add("placeholder");
    }
}

richeditor.insertText = function(text) {
    editor.innerHTML = text;
    richeditor.updatePlaceholder();
    window.webkit.messageHandlers.heightDidChange.postMessage(document.body.offsetHeight);
}

richeditor.setBaseTextColor = function(color) {
    editor.style.color = color;
}

richeditor.setBaseTextColor = function(color) {
    editor.style.color = color;
}

richeditor.setBackgroundColor = function(color) {
    editor.style.backgroundColor = color;
}

richeditor.focus = function() {
    var range = document.createRange();
    range.selectNodeContents(editor);
    range.collapse(false);
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    editor.focus();
}

richeditor.focusAtPoint = function(x, y) {
    var range = document.caretRangeFromPoint(x, y) || document.createRange();
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    editor.focus();
};

richeditor.setPlaceholderText = function(text) {
    editor.setAttribute("placeholder", text);
};

editor.addEventListener("input", function() {
    window.webkit.messageHandlers.textDidChange.postMessage(editor.innerHTML);
    window.webkit.messageHandlers.previewDidChange.postMessage(editor.innerText);
    richeditor.updatePlaceholder();
}, false)

document.addEventListener("selectionchange", function() {
    window.webkit.messageHandlers.heightDidChange.postMessage(editor.clientHeight);
}, false);

document.getElementById("not-editor").addEventListener("click", () => {
    if (editor == document.activeElement) {
        editor.blur();
    } else {
        editor.focus();
        document.execCommand('selectAll', false, null);
        document.getSelection().collapseToEnd();
    }
})

document.addEventListener('paste', e => {
    var items = (event.clipboardData  || event.originalEvent.clipboardData).items;
    if (items[0] && items[0].kind === 'file') {
        e.preventDefault();
    }
});
