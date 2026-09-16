"""Small baked colour maps; exported materials use only image-based PBR."""
import bpy, numpy as np, os
ROOT=os.path.dirname(os.path.abspath(__file__))
os.makedirs(os.path.join(ROOT,'textures'),exist_ok=True)
rng=np.random.default_rng(47)
n=512
y,x=np.mgrid[0:n,0:n]/n
for name in ['honey_oak','oak_edge']+['limestone_%02d'%i for i in range(7)]:
    m=bpy.data.materials[name];p=m.node_tree.nodes.get('Principled BSDF');base=np.array(m.diffuse_color[:3])
    if name.startswith('limestone'):
        noise=rng.normal(0,.012,(n,n))
        flecks=rng.random((n,n));noise+=np.where(flecks>.975,-.08,0)+np.where(flecks<.025,.055,0)
        field=np.clip(base[None,None,:]+noise[:,:,None],0,1)
    else:
        warp=x+.007*np.sin(y*14)+.003*np.sin(y*39+x*7)
        grain=.028*np.sin(warp*650)+.012*np.sin(warp*1400)+.017*np.sin(warp*85)
        grain+=rng.normal(0,.007,(n,n))
        field=np.clip(base[None,None,:]+grain[:,:,None]*np.array([1,.75,.45]),0,1)
    # Encode linear authored colours as sRGB pixels for ordinary PNG colour maps.
    field=np.where(field<=.0031308,field*12.92,1.055*np.power(field,1/2.4)-.055)
    rgba=np.ones((n,n,4),dtype=np.float32);rgba[:,:,:3]=field
    im=bpy.data.images.new(name+'_colour',width=n,height=n,alpha=True);im.pixels.foreach_set(rgba.ravel());im.filepath_raw=os.path.join(ROOT,'textures',name+'_colour.png');im.file_format='PNG';im.save();im.pack()
    node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;m.node_tree.links.new(node.outputs['Color'],p.inputs['Base Color'])
bpy.data.objects['foundation'].location.z=-.16
bpy.context.scene.view_settings.exposure=-.25
