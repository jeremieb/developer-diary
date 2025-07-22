# IMG.LY Document

## Video Presentation

 In this short video, I walk through the document and share my thought process behind the key decisions, tradeoffs, and product ideas included in the assignment.

> ➡️ [Launch the video](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/FDD37E60-E4BF-4D96-96F5-85B9B4B2C164_2/JxH0VS7KMTguVsLInNeN29CHaEi8EN606nNI5UjdpEAz/IMG.ly.m4v)

## PART 1

### Your project

We understand that the goal of this project is to create a mobile journaling app that allows users to capture and personalize their memories through a visually rich editing experience. Users should be able to select a photo from their device, crop it to a square format, apply visual filters, and overlay elements such as text or stickers. Once an edit is complete, the user can save the final image to a personal gallery within the app. Crucially, the app should also support non-destructive editing—allowing users to revisit a journal entry and continue editing from where they left off. This requires maintaining both a rendered image for display and a persistent editing state that can be reloaded. Our proposed solution leverages CE.SDK’s powerful creative editing capabilities to meet these needs, while clearly delineating responsibilities between the SDK and the app’s own logic and UI.

### **The CreativeEditor**

The CreativeEditor SDK (CE.SDK) for iOS offers a robust and comprehensive set of tools that align perfectly with the needs of a creative journaling app. It supports essential features such as image cropping, filter application, and the addition of text or stickers, while also enabling export of the final composition. More importantly, it provides built-in capabilities to serialize and restore complete editing sessions, allowing users to return to their work at any time without losing progress. Together, these features make CE.SDK an ideal foundation for delivering a seamless and engaging mobile journaling experience. The following table outlines the specific CE.SDK components that power these capabilities.

| **Feature**             | **API / Component**                      | **Purpose**                                  |
| ----------------------- | ---------------------------------------- | -------------------------------------------- |
| **Image Import & Crop** | TransformTool, Crop Operation            | Crop to square format                        |
| **Filter Application**  | Adjustment Tool, Effects Tool            | Apply image filters                          |
| **Text & Stickers**     | Scene.addTextBlock(), Scene.addGraphic() | Overlay user-generated content               |
| **Save as Image**       | RenderResult export                      | Final flattened image output                 |
| **Save Editing State**  | Scene Serialization                      | JSON-based file to restore full edit session |

### **Responsibilities Breakdown**

While CE.SDK provides the core creative editing engine, the overall experience requires collaboration between the SDK and the host app. The table below outlines which parts of the functionality are handled by CE.SDK and which need to be implemented within the customer’s application logic and UI:

| **Functionality**         | **CE.SDK Handles** | **Customer App Handles** |
| ------------------------- | ------------------ | ------------------------ |
| Image editing tools       | ✅                  |                          |
| Scene state serialization | ✅                  |                          |
| UI and navigation         |                    | ✅                        |
| File management / saving  |                    | ✅                        |
| Journal gallery UI        |                    | ✅                        |
| Image picker integration  |                    | ✅                        |

### **Image vs. Editing State**

A key distinction in this app’s workflow is the difference between exporting a final image and saving the editable state of a scene. Understanding this separation is essential for enabling both immediate display and future re-editing. Think of it like the difference of an editable Photoshop file versus a flat JPEG file.

- **Saved Image**: A final, flattened bitmap—no further edits possible.
- **Saved Editing State**: A serialized .scene file (JSON) that allows resuming the editing session with layers intact (text, stickers, filters, crop settings).

### High Level Implementation Flow

To support a smooth and engaging user experience, the journaling app must integrate CE.SDK’s editing capabilities within a larger flow that handles image selection, file management, UI presentation, and session persistence. Below is a high-level implementation outline followed by a user journey example to illustrate how different components come together and where developer integration is required.

![Image.png](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/49A80922-A287-4EB0-B74F-73A823FAA2E6_2/mEQwvmN0ufAHtGdbdrSPSDNvsPHo1lQetxy2H8PGdwAz/Image.png)

### **Tradeoffs & Considerations**

While CE.SDK covers the editing capabilities out of the box, a few implementation choices can impact performance and maintainability.

- **Scene File Size**

    Serialized editing sessions are saved as JSON. Embedding assets like stickers or fonts can bloat file size. Linking to local or remote assets is recommended for lighter storage.

- **Media Storage Strategy**

    Final images can be offloaded to a CDN to reduce app storage use and improve performance, especially when managing large galleries or high-res exports.

- **Device Performance**

    Older devices may struggle with complex scenes. Keeping edits efficient—limiting effects and heavy layers—helps maintain a smooth experience.

### **Why CE.SDK is the Right Fit**

CE.SDK for iOS is a strong fit for building a modern, creative journaling app. It covers all core features—cropping, filters, text, stickers—and crucially supports session serialization, so users can return and re-edit memories anytime. While there are a few considerations like storage size or UI consistency when restoring scenes, these are minor tradeoffs compared to the flexibility and maturity the SDK provides.

Looking ahead, CE.SDK’s shared scene format and cross-platform support make it easy to scale the experience beyond iOS—extending to Android or the web with minimal duplication. It’s a future-ready solution that lets your team focus on crafting a seamless, engaging product today, with the confidence to grow tomorrow.

---

## PART 2

### Journaling POC

To validate the feasibility and developer experience, we built a lightweight proof of concept using CE.SDK for iOS. In just a short time, we were able to load an image, apply filters, add text and stickers, and serialize the editing state with minimal setup. The SDK’s modular structure, clear documentation, and ready-to-use UI components made the integration process smooth and intuitive. This POC demonstrates how easily powerful creative features can be embedded into an app, enabling teams to stay focused on delivering a polished, user-centered product.

As a note, the current POC uses **Swift Data** to store memories and associated scene files locally, which may lead to slower app launch times as the database grows. In a production environment, we recommend storing final images and editing states on a **CDN or cloud-based storage**, ensuring faster access, better scalability, and a smoother user experience across devices.


![01.png](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/365AF2AA-D3E3-460F-89A4-1F3C2EB889A1_2/lWDcGNdHU9CQLozyPmdxNL79INzOt3FYk8JbX22TaRoz/01.png)

![02.png](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/1E93EF54-737D-49BA-90FA-99E4FD276FF4_2/bJxg1AXinrvVLUTcEuu17YuOesWJ2OIpeV3P4t1E82Iz/02.png)

![03.png](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/64B4CFEE-AB2F-4D8E-8C2B-C8861C521E6F_2/bcpMCZvLrJYfgsJATxGqNw9qrVFdemRAjmW5HF81qvAz/03.png)

![04.png](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/5211AE59-F927-4537-ADE5-F2D1B74CB60F_2/AR60AsPE8KqPxQAwIuVKz461L3cX4h51py3fnxSPT9gz/04.png)

![05.png](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/D6CDAC3B-D1B5-469E-AE09-ACD981458FF6_2/b79VJzd8jfdpCtQ5LGIy72ILa3wTGReGlptuC2mPeUcz/05.png)

> ➡️ [Github sources](https://github.com/jeremieb/developer-diary/)

---

## PART 3

### **Product Enhancements to Drive Engagement and Delight**

To further elevate the journaling experience and maximize the value of CE.SDK, we believe there are opportunities to reduce friction and deepen emotional engagement through well-integrated system features and smart re-entry points.

### App Intents

One idea is to leverage **Siri Shortcuts and App Intents**, enabling users to instantly “Add a New Memory” via voice or tap—even without opening the app. This lowers the barrier to entry and encourages spontaneous journaling. Even more powerful, Siri can learn user behavior over time—such as when they typically create new entries—and proactively suggest the shortcut at relevant moments (e.g. after a walk, during a commute, or in the evening). By surfacing the journaling action when it matters most, we not only make the editor more accessible, but also build meaningful habits around memory capture—boosting both engagement and emotional relevance.

![Image.jpeg](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/43C7AC4E-64C6-4736-AB25-31270722534E_2/y4xwydlLR1madJEsFwAKfx5jAuAVbmYWsxAFRT0j9ewz/Image.jpeg)

### Widgets

Another valuable enhancement could be **interactive widgets** that re-engage users with their past creations. For example:

- A **“Relive a Memory”** widget that surfaces a random journal entry from the past.
- A **“On This Day”** widget that brings up moments created on this same date in previous years.

These subtle, well-timed nudges can turn passive users into active creators, while reinforcing the emotional value of journaling. With CE.SDK’s scene reloading capabilities, tapping the widget could even re-open the original editing state, inviting the user to reflect, enhance, or annotate with new thoughts.

### Mood Tracker

Additionally, we suggest incorporating a lightweight **mood tracker** during the memory creation flow. When starting a new entry, users could quickly select or log how they feel—whether through a simple emoji, color scale, or short text input. This not only deepens personal context around the memory but also creates opportunities for powerful insights over time (“You tend to capture joyful moments in the mornings”) and for personalization of creative presets (e.g., suggesting warm filters on happy days, softer tones on reflective ones).

![Image.tiff](https://resv2.craft.do/user/full/47de7f02-40eb-a7ec-cf46-a47256d762c1/doc/E32BE1F2-96BB-40A4-BB3D-544E2DCD48AF/5106403F-05AB-400F-A512-C3B272A1A1B8_2/9XJmT24dndpOfERO2xQaRx3q8iNCdWg65oWpq4iCnxQz/Image.tiff)

By integrating these features, we’re not just delivering an editing tool—we’re creating a product that fits seamlessly into users’ lives, helps them build meaningful habits, and brings lasting emotional value. It’s a thoughtful use of CE.SDK’s flexibility that not only improves the user experience but also supports the success and stickiness of the product itself.

Thank you.
