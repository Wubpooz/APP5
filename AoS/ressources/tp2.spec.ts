import {displayPeopleAndLength, returnPeopleAndLength} from './tp2';

const spy = jest.spyOn(console, 'log');

describe('TP2', () => {
    beforeEach(() => {
        spy.mockClear();
     });

    it('returnPeopleAndLength with table in parameter', () => {
        const people: [string, number][] = returnPeopleAndLength();
        expect(people.length).toBe(2);
        expect(people[0][0]).toBe('Miles');
        expect(people[0][1]).toBe(5);
        expect(people[1][0]).toBe('Mick');
        expect(people[1][1]).toBe(4);
    });

    it('returnPeopleAndLength with arguments', () => {
        const people: [string, number][] = returnPeopleAndLength(['Emmanuel']);
        expect(people.length).toBe(1);
        expect(people[0][0]).toBe('Emmanuel');
        expect(people[0][1]).toBe(8);
    });

    it('displayPeopleAndLength with table in parameter', () => {
        displayPeopleAndLength(['Emmanuel']);
        expect(spy).toHaveBeenNthCalledWith(1, 'Emmanuel contient 8 caractères');
    });

    it('displayPeopleAndLength without literals and more than 9 characters', () => {
        displayPeopleAndLength(['Emmanuel', 'Jean-Pierre']);
        expect(spy).toBeCalledWith('Emmanuel contient 8 caractères');
        expect(spy).toBeCalledWith('Jean-Pierre contient 11 caractères');
    });

    it('displayPeopleAndLength without arguments', () => {
        displayPeopleAndLength();
        expect(spy).toBeCalledWith('Miles contient 5 caractères');
        expect(spy).toBeCalledWith('Mick contient 4 caractères');
    });

    it('displayPeopleAndLength with table and literal in parameter', () => {
        displayPeopleAndLength(['Zenika', 'ZenikaZenika'], true);
        expect(spy).toHaveBeenCalledTimes(1);
        expect(spy).toBeCalledWith('Zenika contient six caractères');
    });

});
