#!/bin/bash
node Kha/make html5 --haxe /usr/local/lib/haxe "$@"
cat > build/html5/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <title>Khashooter</title>
    <style>body{margin:0;overflow:hidden;background:#000}canvas{display:block}</style>
</head>
<body>
    <canvas id="khanvas" width="1300" height="800" tabindex="0"></canvas>
    <script src="kha.js"></script>
    <script>
        var c=document.getElementById('khanvas');c.focus();
        c.addEventListener('contextmenu',function(e){e.preventDefault();return false});
        // Expose game globals for Playwright testing
        window.__kha = { app: function() { return refraction_core_Application; } };
    </script>
</body>
</html>
EOF
echo "Build complete. index.html fixed."
