# 图层与动态效果

## 定位绘制来源

在目标视口和状态下定位区域，查看元素、祖先、重叠的相邻节点与 `::before`、`::after`。命中的 DOM 节点不一定负责绘制全部效果，渐变可能来自背景、伪元素、图片、SVG、视频或 canvas。

从实际结构核对层叠上下文、定位、`z-index`、裁切、遮罩、透明度、混合、滤镜与背景滤镜。DOM 顺序不等于最终绘制顺序；`elementsFromPoint()` 可辅助找命中层，但不会单独返回伪元素，也可能遗漏不参与命中测试的装饰层，不能作为完整图层清单。

区分元素自身的 `filter` 与采样后方内容的 `backdrop-filter`，区分半透明颜色与整个元素组的 `opacity`。超出容器的尺寸、裁切和模糊边缘可能共同决定画面，不能只记录一个 `linear-gradient()` 就结束。

## 读取计算样式

将下例选择器替换为已定位的元素，通过浏览器当前版本支持的脚本执行入口求值。只读取与问题有关的属性；需要更多祖先或兄弟层时分别取证，不对整页导出全部样式。

```javascript
(() => {
  const element = document.querySelector("#target");
  if (!element) throw new Error("Target element not found");

  const properties = [
    "content", "display", "position", "z-index", "width", "height",
    "background", "opacity", "filter", "backdrop-filter", "transform",
    "mix-blend-mode", "isolation", "overflow", "clip-path", "mask-image",
    "border-radius", "box-shadow", "pointer-events"
  ];

  const read = (pseudo) => {
    const style = getComputedStyle(element, pseudo);
    return Object.fromEntries(
      properties.map((property) => [property, style.getPropertyValue(property)])
    );
  };

  const rect = element.getBoundingClientRect();
  return {
    viewport: { width: innerWidth, height: innerHeight, dpr: devicePixelRatio },
    rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
    element: read(null),
    before: read("::before"),
    after: read("::after")
  };
})();
```

计算样式是当前状态的解析结果，不等于作者原始声明或最终像素。检查伪元素是否实际生成并可见；取得样式对象不证明存在可见图层。数值涉及变量、百分比、继承或变换时，结合源码和容器解释。[计算样式说明](https://developer.mozilla.org/en-US/docs/Web/API/Window/getComputedStyle)

## 读取运动

在实际触发期间观察进入、持续、退出和中断，区分自动播放、hover、滚动与业务状态变化。必要时在已授权的只读页面重新加载或重现相关动作，不能因动画已结束后的空列表断言页面没有动效。

```javascript
(() => {
  const element = document.querySelector("#target");
  if (!element) throw new Error("Target element not found");

  return element.getAnimations({ subtree: true }).map((animation) => {
    const effect = animation.effect;
    const target = effect?.target;
    const currentTime = animation.currentTime;

    return {
      id: animation.id,
      target: target ? {
        tag: target.tagName,
        id: target.id,
        classes: target.getAttribute?.("class"),
        pseudo: effect.pseudoElement ?? null
      } : null,
      playState: animation.playState,
      currentTime: currentTime == null || typeof currentTime === "number"
        ? currentTime : String(currentTime),
      playbackRate: animation.playbackRate,
      timing: effect?.getComputedTiming?.(),
      keyframes: effect?.getKeyframes?.()
    };
  });
})();
```

将延迟、时长、关键帧、缓动和重复解释为时间关系：例如主要位移是否很早完成、哪些元素依次进入、滚动与进度如何对应。保留决定效果的起止与步进，不输出无用途的长参数表。当前 `opacity: 1` 或 `transform: none` 可能是结束态，也可能就是问题的关键，结合过程判断。[动画读取说明](https://developer.mozilla.org/en-US/docs/Web/API/Element/getAnimations)

该 API 覆盖浏览器管理的相应动画，不覆盖全部逐帧脚本、canvas 或视频。需要确认其他来源时查看相关代码、资源与实际过程，不根据空结果猜测具体库。

## 不可见部分与交付

跨域样式表的规则访问可能受限，但浏览器仍可能提供相关元素的计算样式；区分缺少原始规则和无法观察渲染。canvas 的存在不证明使用 WebGL，不能为探测调用 `getContext()` 创建新的上下文；原始着色器或绘图代码不可读时说明限制。

按核实的绘制顺序解释每层的结构、技术、作用和关键参数，再说明动画如何改变它。指出依赖特定尺寸、字体、素材、性能预算和许可的部分。用户要求代码时给出标明假设的重建示例，不将近似重建称为提取到的原实现。
