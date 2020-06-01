var project = new Project('Empty');

project.addSources('./Sources');
project.addShaders('./Shaders');
//project.addSources('../shooter2016/src');

project.addLibrary('zui');
project.addLibrary("yaml");
project.addLibrary("dconsole");
project.addLibrary("hscript");


project.addAssets('Assets/**', {
	nameBaseDir: 'Assets',
	destination: '{dir}/{name}',
	name: '{dir}/{name}'
});

project.windowOptions.width = 800;
project.windowOptions.height = 600;

resolve(project);

