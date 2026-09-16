"""Blender background authoring source. Metres, +Z up, entry on south wall."""
import bpy, math, random, os, json
from mathutils import Vector
random.seed(27)
ROOT = os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    if c.name != 'Collection': bpy.data.collections.remove(c)
base = bpy.data.collections.get('Collection'); base.name = 'architecture'
groups = {'architecture': base}
for name in ['commission', 'waiting', 'voting_booths', 'ballot_box', 'entrance', 'signage', 'daily_details', 'lighting_fixtures', 'presentation']:
    c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c); groups[name] = c
group = 'architecture'
def put(o, name):
    o.name = name
    for c in list(o.users_collection): c.objects.unlink(o)
    groups[group].objects.link(o)
    return o
def mat(name, rgb, rough=.5, metal=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*rgb,1); p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
    return m
plaster=mat('warm_mineral_paint',(.74,.73,.68),.85)
white=mat('porcelain_powder_coat',(.83,.85,.82),.4)
oak=mat('honey_oak',(.42,.25,.12),.48)
oak_light=mat('oak_edge',(.55,.35,.18),.48)
teal=mat('deep_petrol',(.045,.16,.17),.58)
cloth=mat('woven_sage',(.25,.35,.31),.95)
dark=mat('graphite',(.045,.055,.06),.4)
metal=mat('brushed_aluminium',(.44,.49,.5),.32,.75)
paper=mat('warm_paper',(.89,.88,.82),.78)
ink=mat('signage_ink',(.055,.085,.09),.65)
orange=mat('muted_ochre',(.74,.36,.105),.65)
rubber=mat('rubber',(.045,.049,.043),.95)
soil=mat('pot_soil',(.075,.046,.025),1)
leafmat=mat('leaf_green',(.095,.22,.08),.6)
glass=mat('frosted_polycarbonate',(.63,.76,.73),.22)
glass.node_tree.nodes.get('Principled BSDF').inputs['Transmission Weight'].default_value=.3
glass.node_tree.nodes.get('Principled BSDF').inputs['IOR'].default_value=1.46
emission=mat('opal_diffuser',(.92,.93,.87),.4)
p=emission.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(1,.9,.72,1);p.inputs['Emission Strength'].default_value=2
floor_mats=[mat('limestone_%02d'%i,(.43+i*.008,.45+i*.007,.43+i*.006),.74) for i in range(7)]
def finish(o,m,bevel=0):
    if m:o.data.materials.append(m)
    if bevel:
        mod=o.modifiers.new('manufactured_edge','BEVEL');mod.width=bevel;mod.segments=3
        mod=o.modifiers.new('weighted_normals','WEIGHTED_NORMAL')
    return o
def box(name,loc,dim,m,bevel=.015):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=put(bpy.context.object,name);o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,m,bevel)
def cyl(name,loc,r,depth,m,vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc);o=put(bpy.context.object,name)
    for f in o.data.polygons:f.use_smooth=True
    return finish(o,m,.005)
def rod(name,a,b,r,m):
    a,b=Vector(a),Vector(b);o=cyl(name,(a+b)/2,r,(b-a).length,m,16);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
font=bpy.data.fonts.load('C:/Windows/Fonts/arial.ttf')
bold=bpy.data.fonts.load('C:/Windows/Fonts/arialbd.ttf')
def text(name,body,loc,size,m=ink,rotation=(math.pi/2,0,0),align='LEFT',heavy=False):
    cu=bpy.data.curves.new(name,'FONT');cu.body=body;cu.size=size;cu.font=bold if heavy else font;cu.align_x=align;cu.extrude=.0006
    o=bpy.data.objects.new(name,cu);groups[group].objects.link(o);o.location=loc;o.rotation_euler=rotation;cu.materials.append(m)
    bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False);return o
def mesh(name,verts,faces,m):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);groups[group].objects.link(o);finish(o,m)
    for p in me.polygons:p.use_smooth=True
    return o
def chair(name,x,y,angle=0,upholstery=cloth):
    # Curved upholstered back, separate seat and bent steel legs.
    origin=Vector((x,y,0));co,si=math.cos(angle),math.sin(angle)
    def pt(a,b,z):return (x+a*co-b*si,y+a*si+b*co,z)
    seat=box(name+'_seat',pt(0,0,.47),(.49,.47,.085),upholstery,.045);seat.rotation_euler.z=angle
    vs=[]
    for j in range(7):
        z=.54+j*.055
        for i in range(13):
            t=(i/12-.5)*1.1;vs.append(pt(math.sin(t)*.46,.21+(1-math.cos(t))*.3+(z-.54)*.12,z))
    fs=[(j*13+i,j*13+i+1,(j+1)*13+i+1,(j+1)*13+i) for j in range(6) for i in range(12)]
    o=mesh(name+'_curved_back',vs,fs,upholstery);s=o.modifiers.new('shell_thickness','SOLIDIFY');s.thickness=.035;b=o.modifiers.new('soft_edges','BEVEL');b.width=.015;b.segments=3
    for dx in [-.19,.19]:
        for dy in [-.16,.17]:
            rod(name+'_leg',pt(dx*1.16,dy*1.3,.035),pt(dx,dy,.44),.014,dark)
            cyl(name+'_foot',pt(dx*1.16,dy*1.3,.022),.021,.035,rubber)
def sheet(name,x,y,z,angle=0):
    o=box(name,(x,y,z),(.21,.297,.0018),paper,.001);o.rotation_euler.z=angle
    for k in range(6):
        a=box(name+'_printed_line',(x,y-.08+k*.024,z+.0015),(.145 if k else .11,.003,.0005),teal,0);a.rotation_euler.z=angle

# The footprint has a deep service bay at the north-west and a lowered entrance wing.
box('foundation',(0,0,-.14),(14.5,10.5,.28),dark)
for ix in range(14):
    for iy in range(10):box('stone_slab_%02d_%02d'%(ix,iy),(-6.5+ix,-4.5+iy,-.017),(.996,.996,.032),random.choice(floor_mats),.003)
box('north_wall',(0,5.15,1.9),(14.5,.3,3.8),plaster)
box('east_wall',(7.15,0,1.9),(.3,10,3.8),plaster)
box('south_wall_left',(-2.05,-5.15,1.9),(10.4,.3,3.8),plaster)
box('south_wall_right',(6.25,-5.15,1.9),(1.8,.3,3.8),plaster)
box('entrance_lintel',(4.25,-5.15,3.22),(2.4,.3,1.16),plaster)
box('window_spandrel',(-7.15,0,.4),(.3,10,.8),plaster)
box('window_header',(-7.15,0,3.5),(.3,10,.6),plaster)
for y in [-5,-1.67,1.67,5]:box('window_pier',(-7.12,y,1.9),(.38,.24,3.8),plaster)
for y in [-3.335,0,3.335]:
    box('deep_window_sill',(-6.96,y,.83),(.58,3.1,.075),white)
    box('window_glazing',(-7.17,y,2.0),(.025,3.05,2.3),glass)
    for yy in [y-1.52,y,y+1.52]:box('window_mullion',(-7.03,yy,2.0),(.075,.055,2.32),metal,.006)
    for z in [.86,3.15]:box('window_horizontal_frame',(-7.03,y,z),(.09,3.12,.06),metal,.006)
    box('roller_blind_cassette',(-6.95,y,3.16),(.15,3.08,.12),white)
    box('partially_lowered_blind',(-6.97,y,2.98),(.018,3.02,.3),paper,.002)
for x,y,dim in [(0,4.97,(14,.045,.12)),(6.97,0,(.045,10,.12)),(-6.96,0,(.05,10,.12)),(-2,-4.97,(10,.05,.12))]:box('aluminium_skirting',(x,y,.065),dim,metal,.004)
box('ceiling',(0,0,3.91),(14.5,10.5,.22),plaster)
# Commission bay: oak portal and acoustic petrol backdrop, offset from circulation.
box('commission_backdrop',(-3.25,4.93,1.5),(6.7,.075,2.95),teal)
box('service_bay_bulkhead',(-3.25,3.6,3.25),(7,2.8,.23),oak)
box('service_bay_end',(.23,4.1,1.6),(.2,1.8,3.2),oak)
for i in range(28):box('oak_backdrop_batten',(-6.4+i*.105,4.855,1.5),(.036,.065,2.92),oak_light,.006)
group='commission'
for x in [-4.65,-2.35]:
    box('desk_worktop',(x,2.8,.755),(2.22,.88,.055),oak_light,.025)
    box('desk_front',(x,2.87,.385),(2.14,.055,.66),white)
    for xx in [x-.96,x+.96]:box('desk_leg',(xx,2.8,.36),(.055,.71,.72),dark,.008)
    box('desk_front_inset',(x,2.83,.36),(1.9,.012,.43),teal,.008)
    chair('commission_chair',x,3.6,0,dark)
    sheet('registration_form',x-.28,2.6,.789,.04)
    box('document_tray',(x+.68,2.92,.81),(.29,.34,.06),dark)
    for i in range(4):box('form_stack',(x+.68,2.92,.849+i*.005),(.265,.31,.004),paper,.001)
    box('laptop_base',(x+.25,2.89,.8),(.34,.24,.02),dark,.008)
    o=box('laptop_screen',(x+.25,3.0,.92),(.34,.018,.23),dark,.009);o.rotation_euler.x=math.radians(-12)
    box('desk_nameplate',(x-.73,2.49,.86),(.3,.045,.12),white,.006)
    text('desk_number','01' if x<-3 else '02',(x-.84,2.463,.834),.065,teal,heavy=True)
    cyl('pen_cup',(x-.65,2.95,.84),.035,.105,teal)
    for i in range(3):rod('desk_pen',(x-.66+i*.012,2.95,.82),(x-.65+i*.012,2.95,.96),.003,ink)
for x in [-4.95,-3.88,-2.81]:
    box('archive_cabinet',(x,4.56,.43),(1.02,.6,.84),white)
    for xx in [x-.25,x+.25]:
        box('cabinet_door',(xx,4.245,.44),(.485,.025,.74),white,.006)
        box('cabinet_pull',(xx+.16,4.22,.55),(.018,.03,.14),metal,.005)
group='signage'
text('commission_title','ИЗБИРАТЕЛЬНЫЙ УЧАСТОК',(-3.15,4.8,2.38),.205,white,heavy=True)
text('commission_subtitle','КОМИССИЯ  /  РЕГИСТРАЦИЯ',(-3.13,4.8,2.03),.12,white)
text('station_number','№ 0147',(-3.13,4.8,1.64),.23,white)

# Two roomy booths: one accessible, one standard, both face the open centre.
group='voting_booths'
for idx,(x,w) in enumerate([(2.45,1.65),(4.65,1.65)]):
    y=3.82
    for xx in [x-w/2,x+w/2]:
        box('booth_side_panel',(xx,y,1.18),(.055,1.8,2.16),white,.015)
        box('booth_petrol_outer_strip',(xx,y-.65,1.25),(.06,.3,2.0),teal,.006)
        for yy in [y-.8,y+.8]:cyl('booth_leveling_foot',(xx,yy,.055),.045,.08,dark)
    box('booth_back_panel',(x,y+.87,1.18),(w,.06,2.16),white)
    box('booth_writing_shelf',(x,y+.4,.79),(w-.08,.58,.04),oak_light)
    sheet('voting_paper',x,y+.37,.813)
    rod('booth_pen',(x+.3,y+.28,.818),(x+.31,y+.44,.818),.005,teal)
    box('booth_header',(x,y-.88,2.22),(w+.08,.075,.2),teal)
    text('booth_label','КАБИНА  0'+str(idx+1),(x-w/2+.12,y-.922,2.175),.1,white)
    rod('curtain_rail',(x-w/2,y-.82,2.13),(x+w/2,y-.82,2.13),.015,metal)
    # Gathered cloth with actual mesh folds; opening is kept clear for the player.
    vs=[];fs=[]
    for j in range(17):
        for i in range(37):
            u=i/36;v=j/16
            vs.append((x+w/2-.43+u*.39,y-.81+math.sin(u*math.pi*10)*(.027+.012*v),2.1-v*1.9+.014*math.sin(u*math.pi*10)*v))
    for j in range(16):
        for i in range(36):a=j*37+i;fs.append((a,a+1,a+38,a+37))
    o=mesh('gathered_privacy_curtain',vs,fs,cloth);s=o.modifiers.new('fabric_thickness','SOLIDIFY');s.thickness=.003
    for i in range(6):
        bpy.ops.mesh.primitive_torus_add(major_radius=.024,minor_radius=.004,major_segments=16,minor_segments=8,location=(x+w/2-.42+i*.073,y-.81,2.125),rotation=(0,math.pi/2,0));finish(put(bpy.context.object,'curtain_ring'),metal)
    box('booth_task_light',(x,y+.81,1.96),(.5,.07,.035),emission,.005)

group='ballot_box'
x,y=2.55,.38
box('ballot_box_plinth',(x,y,.065),(.82,.73,.13),teal,.035)
for xx in [x-.35,x+.35]:
    for yy in [y-.3,y+.3]:box('ballot_box_corner',(xx,yy,.61),(.035,.035,1.04),metal,.006)
for xx in [x-.35,x+.35]:box('ballot_box_side',(xx,y,.6),(.008,.59,.98),glass,.003)
for yy in [y-.3,y+.3]:box('ballot_box_front',(x,yy,.6),(.68,.008,.98),glass,.003)
box('ballot_box_base',(x,y,.15),(.71,.61,.04),white)
# Lid is split around a real ballot aperture.
for dy in [-.183,.183]:box('urn_lid_half',(x,y+dy,1.15),(.8,.32,.065),white,.014)
for dx in [-.287,.287]:box('urn_slot_end',(x+dx,y,1.15),(.225,.046,.065),white,.005)
box('slot_dark_throat',(x,y,1.122),(.35,.03,.01),dark,.001)
box('urn_label',(x,y-.312,.74),(.49,.012,.28),white,.009)
text('urn_label_text','БЮЛЛЕТЕНИ',(x,y-.321,.754),.058,teal,align='CENTER',heavy=True)
text('urn_label_number','0147',(x,y-.321,.65),.075,teal,align='CENTER')
for dx in [-.27,.27]:
    box('urn_latch',(x+dx,y-.35,1.105),(.045,.025,.09),metal,.004)
    rod('seal_wire',(x+dx,y-.37,1.09),(x+dx+.025,y-.37,1.0),.002,orange)
    box('numbered_seal',(x+dx+.025,y-.37,.99),(.035,.012,.055),orange,.004)
for i in range(7):sheet('cast_ballot',x+random.uniform(-.13,.13),y+random.uniform(-.1,.1),.175+i*.004,random.uniform(-.4,.4))

group='waiting'
for y in [-2.75,-1.94,-1.13]:chair('visitor_chair',-5.84,y,math.pi/2)
box('waiting_side_table',(-5.8,.02,.43),(.62,.65,.055),oak_light,.03)
for x in [-6,-5.6]:
    for y in [-.19,.23]:rod('table_leg',(x,y,.03),(x,y,.4),.016,dark)
sheet('waiting_leaflet',-5.77,.03,.462,.13)
group='entrance'
box('recessed_entry_mat',(4.25,-4.12,.007),(2.2,1.62,.012),rubber,.025)
for i in range(40):box('mat_rib',(3.2+i*.054,-4.12,.015),(.015,1.53,.004),dark,.001)
for x in [3.12,4.25,5.38]:box('entry_frame',(x,-5.02,1.32),(.065,.12,2.64),dark,.006)
box('entry_transom',(4.25,-5.02,2.65),(2.32,.12,.07),dark,.006)
for x in [3.69,4.81]:
    box('entrance_glazed_leaf',(x,-5.035,1.34),(1.05,.025,2.55),glass,.004)
    box('door_safety_band',(x,-4.999,1.18),(1.05,.01,.16),white,.001)
    rod('door_pull',(x+(-.37 if x>4 else .37),-4.89,1.0),(x+(-.37 if x>4 else .37),-4.89,1.43),.014,metal)
box('exit_sign',(4.25,-4.92,2.94),(.62,.04,.23),teal,.01)
text('exit_text','ВЫХОД',(4.25,-4.89,2.88),.115,white,rotation=(math.pi/2,0,math.pi),align='CENTER')

group='signage'
# Freestanding information wall draws people left, away from the ballot queue.
box('information_panel',(-2.15,-3.4,1.32),(2.9,.14,2.55),teal,.035)
for x in [-3.3,-1]:box('information_panel_foot',(x,-3.4,.035),(.12,.65,.07),dark)
text('information_title','ИНФОРМАЦИЯ',(-.94,-3.305,2.24),.19,white,rotation=(math.pi/2,0,math.pi))
# Front faces toward +Y: mirrored placement order corrected by local rotation.
for x in [-2.93,-2.14,-1.35]:
    box('notice_frame',(x,-3.315,1.48),(.65,.025,.89),metal,.008)
    box('notice_paper',(x,-3.294,1.48),(.6,.009,.84),paper,.002)
    for k in range(16):box('notice_print',(x,-3.286,1.78-k*.039),(.43 if k%5 else .3,.002,.006 if k else .018),ink,0)
    box('notice_heading',(x,-3.283,1.84),(.49,.003,.033),teal,0)
text('booth_wayfinding','03  /  ГОЛОСОВАНИЕ',(1.58,4.965,2.85),.155,teal,heavy=True)

group='daily_details'
# Radiators, a water station, recycling, power points and plants establish use.
for y in [-3.33,0,3.33]:
    box('radiator_body',(-6.83,y,.43),(.16,1.5,.53),white)
    for k in range(19):box('radiator_rib',(-6.73,y-.7+k*.077,.44),(.045,.027,.44),white,.008)
    rod('radiator_pipe',(-6.83,y+.8,.13),(-6.83,y+.8,.62),.015,white)
for x in [-4.3,.65,6.4]:
    box('wall_socket',(x,4.975,.32),(.085,.026,.085),white,.008)
    for dx in [-.018,.018]:
        o=cyl('socket_hole',(x+dx,4.958,.32),.005,.008,dark,12);o.rotation_euler.x=math.pi/2
box('water_cooler',(6.56,-2.95,.52),(.52,.5,1.04),white,.045)
box('water_recess',(6.56,-3.207,.77),(.35,.018,.3),dark,.018)
for x in [6.48,6.65]:rod('cooler_tap',(x,-3.22,.83),(x,-3.27,.83),.014,metal)
cyl('water_bottle',(6.56,-2.95,1.23),.17,.35,glass)
cyl('water_bottle_neck',(6.56,-2.95,1.055),.07,.07,glass)
cyl('waste_bin',(5.76,-3.03,.3),.19,.6,metal)
cyl('waste_bin_rim',(5.76,-3.03,.61),.195,.03,dark)
cyl('waste_bin_inset',(5.76,-3.03,.605),.16,.018,rubber)
def plant(name,x,y):
    bpy.ops.mesh.primitive_cone_add(vertices=48,radius1=.22,radius2=.29,depth=.52,location=(x,y,.26));finish(put(bpy.context.object,name+'_planter'),plaster,.015)
    cyl(name+'_soil',(x,y,.514),.265,.014,soil)
    for i in range(20):
        t=random.random()*math.tau;h=random.uniform(.9,1.65);r=random.uniform(.25,.6)
        start=(x,y,.52);end=(x+math.cos(t)*r,y+math.sin(t)*r,h)
        rod(name+'_stem',start,end,.005,leafmat)
        center=Vector(end);direction=Vector((math.cos(t),math.sin(t),.3));side=Vector((-math.sin(t),math.cos(t),0))*.09
        vs=[center-direction*.15,center+side+Vector((0,0,.04)),center+direction*.32,center-side+Vector((0,0,.04)),center+Vector((0,0,.065))]
        o=mesh(name+'_leaf',vs,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],leafmat);s=o.modifiers.new('leaf_thickness','SOLIDIFY');s.thickness=.001
plant('window_plant',-5.94,1.28);plant('entry_plant',6.22,-4.39)
# Restrained wear: chair scuffs and a small set of contact marks at skirting height.
wear=mat('subtle_contact_marks',(.42,.43,.4),.92)
for i in range(9):
    box('skirting_contact_mark',(-6.931,-2.9+i*.21,.11+random.uniform(-.02,.02)),(.001,random.uniform(.02,.06),.004),wear,0)
box('fire_extinguisher_mount',(6.95,-.9,.65),(.04,.24,.58),dark)
red=mat('extinguisher_red',(.49,.04,.027),.38)
cyl('fire_extinguisher',(6.79,-.9,.57),.115,.44,red)
box('extinguisher_handle',(6.79,-.9,.84),(.18,.07,.045),dark)
rod('extinguisher_hose',(6.79,-.81,.81),(6.66,-.8,.42),.015,dark)

group='lighting_fixtures'
for x in [-3.6,0,3.6]:
    for y in [-1.6,1.45]:
        box('acoustic_raft',(x,y,3.55),(2.6,1.32,.1),white,.025)
        for xx in [x-1.05,x+1.05]:
            for yy in [y-.45,y+.45]:rod('raft_suspension',(xx,yy,3.6),(xx,yy,3.79),.004,metal)
        box('linear_luminaire',(x,y,3.475),(1.95,.12,.065),dark,.008)
        box('luminaire_diffuser',(x,y,3.438),(1.88,.095,.012),emission,.004)
for x in [-5.4,5.9]:
    box('ceiling_vent',(x,0,3.784),(.46,1.35,.03),metal,.006)
    for k in range(14):box('vent_louvre',(x,-.6+k*.092,3.765),(.4,.04,.018),dark,.002)

group='presentation'
def area(name,loc,target,power,color,size,shape='DISK',size_y=None):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.color=color;d.shape=shape;d.size=size
    if size_y is not None:d.size_y=size_y
    o=bpy.data.objects.new(name,d);groups[group].objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
for y in [-3.3,0,3.3]:area('window_daylight',(-6.83,y,2.45),(0,y,.5),550,(.81,.9,1),2.8,'RECTANGLE',2)
for x in [-3.6,0,3.6]:
    for y in [-1.6,1.45]:area('ceiling_soft_light',(x,y,3.39),(x,y,0),145,(1,.91,.77),2.1,'RECTANGLE',.9)
area('commission_light',(-3.3,3.4,3.08),(-3.3,3,0),170,(1,.89,.74),4,'RECTANGLE',1)
def camera(name,loc,target,lens):
    d=bpy.data.cameras.new(name);o=bpy.data.objects.new(name,d);groups[group].objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();d.lens=lens;d.clip_start=.05;return o
cam=camera('01_entry_overview',(5.45,-4.65,1.78),(-.9,2.5,1.45),23)
camera('02_commission_and_windows',(1.2,.25,1.73),(-3.6,3.25,1.48),25)
camera('03_voting_and_urn',(-1.1,-.75,1.65),(3.85,3,1.3),30)
camera('04_reverse_waiting',(1.1,2,1.72),(-2.8,-3.5,1.2),24)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.23,.23,.23)
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
import runpy
runpy.run_path(os.path.join(ROOT,'surface_finish.py'))
# Apply export-safe geometry modifiers and transforms, retain separate semantic objects.
for o in list(bpy.data.objects):
    if o.type=='MESH':
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        for mod in list(o.modifiers):
            try:bpy.ops.object.modifier_apply(modifier=mod.name)
            except RuntimeError:pass
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.data.objects:
    if o.type=='MESH':o.select_set(True)
os.makedirs(os.path.join(ROOT,'renders'),exist_ok=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,'polling_station_reimagined.glb'),export_format='GLB',use_selection=True,export_yup=True,export_cameras=False,export_lights=False)
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active=cam
# Open the file to a composed material-preview camera view.
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':a.spaces.active.region_3d.view_perspective='CAMERA';a.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'polling_station_reimagined.blend'))
stats={'mesh_objects':sum(o.type=='MESH' for o in bpy.data.objects),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in bpy.data.objects if o.type=='MESH'),'materials':len(bpy.data.materials),'dimensions_m':[14,10,3.8]}
with open(os.path.join(ROOT,'scene_stats.json'),'w') as f:json.dump(stats,f,indent=2)
for name in ['01_entry_overview','03_voting_and_urn','04_reverse_waiting']:
    scene.camera=bpy.data.objects[name];scene.render.filepath=os.path.join(ROOT,'renders',name+'.png');bpy.ops.render.render(write_still=True)
print('ART_BUILD_COMPLETE',stats)
