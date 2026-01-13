import {HelloWorld} from './tp1';

describe('TP1', () => {

    let helloWorld: HelloWorld;

    beforeEach(() => {
        helloWorld = new HelloWorld();
    });

    it('should say hello to Zenika', () => {
        expect(helloWorld.sayHello('Zenika')).toBe('Hello Zenika!');
    });

    it('should say hello to World', () => {
        expect(helloWorld.sayHello()).toBe('Hello World!');
    });
});
