# CBL 4 Challenge Workbook: Real ini (RealityBooth)
**Precision 1:1 Scale Spatial AR Visualizer for 3D Printing Makers & Exhibition Booth Designers**

- **Project Name:** Real ini (RealityBooth)
- **Author / Developer:** Steven Valentino
- **Frameworks & Tooling:** RealityKit, ARKit, SwiftUI, LiDAR Scene Reconstruction, CoreHaptics, Combine
- **Target Platforms:** iOS (LiDAR-enabled iPhone & iPad)
- **Challenge Track:** Challenge Based Learning 4 (CBL 4) — Apple Developer Academy

---

## Executive Summary

**Real ini** is an iOS spatial computing application engineered to bridge the gap between digital 3D model design and real-world physical scale. Designed specifically for 3D printing makers and exhibition booth designers, the app allows users to import custom 3D models (`.usdz`, `.usdc`, `.reality`) and project them in their actual physical environment with exact, millimeter-accurate **1:1 true scale**.

By leveraging Apple's native LiDAR sensors, advanced raycasting, realistic multi-point soft studio lighting, stepped tactile haptics, and Apple HIG-compliant dimension callouts, Real ini eliminates costly printing miscalculations and enables booth designers to pitch spatial layouts directly on venue floors.

---

## Phase 1: Engage

### 1.1 The Big Idea
**Spatial Computing & Physical Scale Verification**
Digital 3D modeling environments (Blender, Nomad Sculpt, CAD, Maya) present assets in normalized viewports where physical depth and relative scale are lost. As a result, creators struggle to gauge how a digital object will translate into physical reality before investing significant time, materials, and money.

### 1.2 The Essential Question
> *How might we enable 3D makers and designers to verify real-world physical scale and spatial presence accurately before committing to physical production or staging?*

### 1.3 The Challenge Statement
> *Design and engineer a studio-grade iOS spatial AR utility that renders imported 3D assets at true 1:1 scale with live dimensional feedback, zero-floating ground anchoring, and intuitive multi-touch surface interaction.*

---

## Phase 2: Investigate

### 2.1 Guiding Questions & Technical Research

| Guiding Question | Research & Technical Discovery | Implementation Decision |
| :--- | :--- | :--- |
| **GQ1: Why do existing AR QuickLook tools feel inaccurate for makers?** | Standard AR QuickLook auto-scales models to fit the camera view on launch, obscuring true dimensions. Furthermore, lack of haptic notches at 100% makes finding exact 1:1 scale tedious. | Enforce absolute 100% (1:1) scale upon initial placement, accompanied by a distinct tactile notch and instant reset button. |
| **GQ2: How can we prevent 3D models from "floating" or jittering on surfaces?** | Naive hit-testing against feature points causes jitter. ARKit plane raycasting with container-space clamping ensures firm surface anchoring. | Implemented `ARSurfaceManager` with prioritized raycasting (`.existingPlaneUsingGeometry` -> `.estimatedHorizontalPlane`) and continuous ground clamping (`y = 0.0m`). |
| **GQ3: What dimensional feedback is most useful for physical makers?** | Makers think in metric centimeters (W × L × H). Raw coordinate bounds in meters need real-time transformation and projection to screen space. | Live floating HUD badge dynamically calculating dimensions in cm `[Width × Length × Height]` alongside the active scale percentage (5% – 500%). |
| **GQ4: How do we handle heavy 3D assets without thermal throttling?** | High-framerate 4K camera pipelines combined with multi-directional lighting and complex polygon meshes cause severe thermal buildup and frame drops. | Locked AR session video format to optimized 1080p 60 FPS format; disabled heavy post-processing and fine-tuned light attenuation. |
| **GQ5: How should multi-model positioning be handled on touch?** | Tap-to-move causes abrupt teleportation. 1-finger drag allows continuous surface sliding. | Created single-finger pan gesture delegating to continuous raycast updates with touch-to-center offset preservation. |

---

## Phase 3: Act (Engineering & System Architecture)

### 3.1 Technical Architecture (MVVM + RealityKit Engine)

```
┌────────────────────────────────────────────────────────┐
│                   SwiftUI HUD Layer                    │
│  ContentView • TopHUDBarView • InstructionBannerView  │
│    ScaleFeedbackBadgeView • ShutterButtonView          │
└───────────────────────────▲────────────────────────────┘
                            │ @Published / @MainActor
┌───────────────────────────┴────────────────────────────┐
│              ARViewModel (ObservableObject)            │
│   Model Lifecycle • Selection State • Scale Timers     │
│   PhotoLibrary Integration • Error Handling Pipeline   │
└───────────────────────────▲────────────────────────────┘
                            │ UIViewRepresentable Bridge
┌───────────────────────────┴────────────────────────────┐
│               RealityKit & ARKit Engine                │
│   ARViewContainer • ARWorldTrackingConfiguration       │
│   ARSurfaceManager (LiDAR Raycasting & Sliding)        │
│   ARSelectionIndicator (Procedural Mesh Ring)          │
│   3-Point Studio Lighting Rig (Key, Fill, Top Lights)  │
└────────────────────────────────────────────────────────┘
```

### 3.2 Core Implemented Features

1. **Precision 1:1 Scale Engine & Apple HIG Dimension Badge:**
   - Visual bounding box calculation transformed into real-world metric dimensions (`W × L × H cm`).
   - Dynamic floating badge anchored above the selected model with real-time percentage and dimensional updates.
   - Stepped haptic ticks at 5% zoom intervals with a heavy notch when snapping to 100% 1:1 scale.

2. **LiDAR Grounding & 1-Finger Surface Sliding:**
   - Multi-tier raycast pipeline ensuring zero floating on floors and tables.
   - 60 FPS smooth dragging across continuous surfaces without jumping or model jitter.

3. **Multi-Point Studio Lighting Rig:**
   - Key Light (3200 lux), Fill Light (2200 lux), and Top Light (2400 lux) configured with `isRealWorldProxy = true`.
   - Preserves fine surface details, material textures, and overhangs for 3D printing inspections.

4. **Multi-Model Scene Management:**
   - Support for up to 4 simultaneous 3D models (`ARConstants.maxSimultaneousModels`).
   - Procedural selection ring indicating active target without obscuring base geometry.

5. **Universal 3D Asset Ingestion:**
   - Seamless support for `.usdz`, `.usdc`, and `.reality` files.
   - Ingestion via custom document picker, AirDrop, and system Files app with asynchronous dependency resolution.

6. **Thermal & Resource Optimization:**
   - Enforced 1080p 60fps video capture format to prevent device overheating during extended AR sessions.
   - Selective disabling of unneeded render options for rock-solid framerates.

---

## Phase 4: CBL Skills Reflection (Tech • Design • Professional)

Grounding learning achievements according to the Apple Developer Academy Challenge Based Learning rubric:

### 4.1 Tech Domain
- **RealityKit & ARKit Deep Integration:** Mastered coordinate transformations, `Entity` hierarchy, `AnchorEntity` lifecycle, and raycast algorithms beyond high-level presets.
- **Swift Concurrency & State Isolation:** Applied `@MainActor`, `async/await`, and Combine pipelines to eliminate data races between ARKit background frame updates and SwiftUI rendering.
- **Procedural Mesh Generation:** Programmatically constructed low-overhead circular selection indicators with custom geometry and unlit materials.
- **Performance & Thermal Profiling:** Identified hardware bottlenecks in camera ISP processing; optimized video formats to maintain 60 FPS without thermal throttling.
- **Asset Pipeline Handling:** Built robust file import handlers capable of resolving USD dependencies and sandboxed file access.

### 4.2 Design Domain
- **Apple HIG for Spatial Computing:** Designed unobtrusive HUD overlays adhering to translucent material standards (Liquid Glass / Ultra-thin materials).
- **Spatial Feedback & Micro-interactions:** Designed continuous visual and haptic feedback (stepped notch haptics, instructional dynamic banners, shutter flash animations).
- **First-Time User Experience (FTUX):** Built contextual tutorial cards and instruction banners that guide users step-by-step through surface scanning, placement, and scaling.
- **App Icon & Branding:** Crafted custom branding for "Real ini" featuring precision spatial iconography and professional visual typography.

### 4.3 Professional Domain
- **Self-Regulated Learning:** Rapidly mastered RealityKit, USD/USDC schemas, and LiDAR raycasting from official Apple documentation, WWDC sessions, and hands-on experiments.
- **Scoping & Agile Iteration (MVP Focus):** Narrowed project scope from generic AR viewing to high-value, niche precision scale verification for makers and booth designers.
- **User-Centered Research:** Interviewed 3D printing hobbyists and exhibition designers to uncover real-world pain points with miscalculated dimensions.
- **Delivery & Distribution:** Packaged the application for TestFlight distribution, established release documentation, privacy policy, and support channels.

---

## Key Takeaways & Future Roadmap

### Key Takeaways
1. **Physical Constraints Rule AR:** Spatial apps cannot treat the world as a static canvas. Floor detection, ambient lighting, and hardware thermals dictate usability just as much as UI layout.
2. **Haptics + Dimensioning Creates Trust:** Digital scale is abstract until paired with metric measurement feedback and physical haptic notches.
3. **Clean Architecture Protects AR Projects:** Separating AR scene management (`ARSurfaceManager`) from state (`ARViewModel`) and presentation (`SwiftUI`) was vital for rapid debugging.

### Future Roadmap
- [ ] **Spatial Audio:** Implement RealityKit spatial sound emitters for booth ambient acoustic simulation.
- [ ] **Custom Shaders (Reality Composer Pro):** Add cross-section slice visualization to inspect internal infill for 3D prints.
- [ ] **visionOS Migration:** Port the core entity-component architecture to Apple Vision Pro Shared and Immersive Spaces.
- [ ] **Cloud Asset Catalog:** Support streaming USDZ assets directly from cloud repositories.
