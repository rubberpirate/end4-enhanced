The spring solver, animation phases and cubic smooth-min liquid field are adapted
from [jrnxf/drip](https://github.com/jrnxf/drip), revision
`e18afd54a31687022829ba96ce42ace3751caf71`, specifically `Spring.swift`,
`Island.swift` and `Droplet.swift`. The renderer is a Qt ShaderEffect port;
the source is the existing Quickshell bar island rather than a new notch.

Rebuild the checked-in shader after changing its source:

```sh
/usr/lib/qt6/bin/qsb --glsl '100 es,120,150' --hlsl 50 --msl 12 -o modules/ii/notificationPopup/shaders/liquid.frag.qsb modules/ii/notificationPopup/shaders/liquid.frag
```

MIT License

Copyright (c) 2026 Colby Thomas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

