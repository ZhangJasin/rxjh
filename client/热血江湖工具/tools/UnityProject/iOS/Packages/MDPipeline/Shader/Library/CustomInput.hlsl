//用于设置一些根据项目类型不同,配置需要定死的参数/可手动或者依靠代码修改
//最大可用灯光数，包含编辑器预览时 cbfr用了如果最大光源数超出32，这里也得改
#define MAX_VISIBLE_LIGHTS (32)
//legacy衰减还是InverseSquared衰减 //和美术确认下需要builtIn的光照衰减还是URP,SRP的，再确认这个要1.还是0
#define LIGHT_FALLOFF_SRP (1)
//useCameraRelativeRendering  相对坐标渲染，根据项目来
//#define CAMERA_RELATIVE_RENDERING (1)
//gammaSpaceUI 开启后线性空间下使用Gamma管线 _USE_FAST_SRGB_LINEAR_CONVERSION 用于 快速转换颜色
//#define _LINEARTOSRGB (1)
//#define _SRGBTOLINEAR (1)
#define _USE_FAST_SRGB_LINEAR_CONVERSION (1)

//深度图使用RGBA32来存储
#define DEPTH_FORMAT_ARGB32 (24)

