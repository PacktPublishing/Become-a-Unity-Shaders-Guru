# Become a Unity Shaders Guru

<a href="https://www.packtpub.com/product/become-a-unity-shaders-guru/9781837636747?utm_source=github&utm_medium=repository&utm_campaign=9781803235851"><img src="https://content.packt.com/B19397/cover_image_small.jpg" alt="" height="256px" align="right"></a>

This is the code repository for [Become a Unity Shaders Guru](https://www.packtpub.com/product/become-a-unity-shaders-guru/9781837636747?utm_source=github&utm_medium=repository&utm_campaign=9781803235851), published by Packt.

**Create advanced game visuals using code and graph**

## What is this book about?

* This book covers the following exciting features:
* Understand the main differences between the legacy render pipeline and the SRP
* Create shaders in Unity with HLSL code and the Shader Graph 10 tool
* Implement common game shaders for VFX, animation, procedural generation, and more
* Experiment with offloading work from the CPU to the GPU
* Identify different optimization tools and their uses
* Discover useful URP shaders and re-adapt them in your projects

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/B0BJKNRCDN) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png" 
alt="https://www.packtpub.com/" border="5" /></a>

## Instructions and Navigations
All of the code is organized into folders. For example, Chapter02.

The code will look like the following:
```
using UnityEngine;
using UnityEngine.Rendering;
[CreateAssetMenu(menuName = "Compute Assets/CH07/FillWithRed")]
public class ComputeFillWithRed : URPComputeAsset {
    public override void Render(CommandBuffer commandBuffer,
        int kernelHandle) {}
}
```

**Following is what you need for this book:**
This book is for technical artists who have worked with Unity and want to get a deeper understanding of Unity's render pipelines and its visual node-based editing tool. Seasoned game developers who are looking for reference shaders using the recent URP render pipeline will also find this book useful. A basic level of programming experience in HLSL, Unity, its layout, and its basic usage is a must.

With the following software and hardware list you can run all code files present in the book (Chapter 1-15).
### Software and Hardware List
| Chapter | Software required | OS required |
| -------- | ------------------------------------ | ----------------------------------- |
| 1-15 | Unity 2022 LTS (Unity 2022.3.11f1) | Windows, Mac OS X, and Linux |

We also provide a PDF file that has color images of the screenshots/diagrams used in this book. [Click here to download it](https://packt.link/rE7c8).

### Related products
* Unity 2021 Cookbook - Fourth Edition [[Packt]](https://www.packtpub.com/product/unity-2021-cookbook-fourth-edition/9781839217616?utm_source=github&utm_medium=repository&utm_campaign=9781839217616) [[Amazon]](https://www.amazon.com/dp/1839217618)

* Game Development Patterns with Unity 2021 - Second Edition [[Packt]](https://www.packtpub.com/product/game-development-patterns-with-unity-2021-second-edition/9781800200814?utm_source=github&utm_medium=repository&utm_campaign=9781800200814) [[Amazon]](https://www.amazon.com/dp/1800200811)

## Get to Know the Author
**Mina Pêcheux** is a freelance content creator who has been passionate about game development since an early age. She is a graduate of the French Polytech School of Engineering in applied mathematics and computer science. After a couple of years of working as a data scientist and web developer in startups, she turned to freelancing and online instructional content creation to reconnect with what brightens her days: learning new things everyday, sharing with others and creating multi-field projects mixing science, technology, and art.
