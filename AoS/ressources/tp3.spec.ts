import {Album, display, JazzMusician, Music, Musician, RockStar} from './tp3';
import SpyInstance = jest.SpyInstance;

describe('TP3', () => {

    let spy: SpyInstance;

    beforeEach(() => {
        spy = jest.spyOn(console, 'log');
        spy.mockClear();
    });

    it('Album properties testing', () => {
        const al = new Album('Kind Of Blue');
        expect(al.title).toBe('Kind Of Blue');
    });

    it('Album toString method testing', () => {
        const al = new Album('Kind Of Blue');
        expect(al.toString()).toBe('Kind Of Blue');
    });

    it('Enum Music testing', () => {
        expect(Music[0]).toBe('JAZZ');
        expect(Music[1]).toBe('ROCK');
    });

    it('Musician properties testing', () => {
        const musician = new Musician('Miles', 'Davis', 89);
        expect(musician.firstName).toBe('Miles');
        expect(musician.lastName).toBe('Davis');
        expect(musician.age).toBe(89);
        expect(musician.albums).toHaveLength(0);
        expect(musician.style).toBeFalsy();
    });

    it('Musician addAlbum testing', () => {
        const musician = new Musician('Miles', 'Davis', 89);
        musician.addAlbum(new Album('Kind Of Blue'));
        musician.addAlbum(new Album('Tutu'));
        expect(musician.albums).toHaveLength(2);
    });

    it('JazzMusician properties testing', () => {
        const musician = new JazzMusician('Miles', 'Davis', 89);
        expect(musician.style).toBe(Music.JAZZ);
    });

    it('JazzMusician toString method testing', () => {
        const musician = new JazzMusician('Miles', 'Davis', 89);
        expect(musician.toString()).toBe('Miles Davis plays JAZZ');
    });

    it('RockStar properties testing', () => {
        const musician = new RockStar('Mick', 'Jagger', 72);
        expect(musician.style).toBe(Music.ROCK);
    });

    it('RockStar toString method testing', () => {
        const musician = new RockStar('Mick', 'Jagger', 72);
        expect(musician.toString()).toBe('Mick Jagger plays ROCK');
    });

    it('display method testing with musicians', () => {
        const musicians: Musician[] = [new JazzMusician('Miles', 'Davis', 89), new RockStar('Mick', 'Jagger', 72)];

        display(musicians);

        expect(spy).toBeCalledTimes(2);
        expect(spy.mock.calls[0][0]).toBe('Miles Davis plays JAZZ');
        expect(spy.mock.calls[1][0]).toBe('Mick Jagger plays ROCK');
    });

    it('display method testing with albums', () => {
        const albums: Album[] = [new Album('Kind Of Blue'), new Album('Tutu')];

        display(albums);

        expect(spy).toBeCalledTimes(2);
        expect(spy.mock.calls[0][0]).toBe('Kind Of Blue');
        expect(spy.mock.calls[1][0]).toBe('Tutu');
    });

});
