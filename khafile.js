var project = new Project('Empty');

project.addSources('./Sources');
project.addShaders('./Sources/Shaders/**');
project.addSources('../shooter2016/src');
project.addAssets('./Sources/bin/**');
project.addLibrary('zui');

resolve(project);

