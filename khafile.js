var project = new Project('Empty');

project.addSources('./Sources');
project.addShaders('./Shaders');
//project.addSources('../shooter2016/src');

project.addLibrary("nape-haxe4");
project.addLibrary('zui');
project.addLibrary("yaml");
project.addLibrary("dconsole");
project.addLibrary("hscript");


project.addAssets('Assets/**', {
	nameBaseDir: 'Assets',
	destination: '{dir}/{name}',
	name: '{dir}/{name}'
});

project.windowOptions.width = 1300;
project.windowOptions.height = 800;

project.targetOptions.html5.disableContextMenu = true;

resolve(project);

