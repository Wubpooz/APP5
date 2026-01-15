enum NumberToString {
  zero = 0,
  un = 1,
  deux = 2,
  trois = 3,
  quatre = 4,
  cinq = 5,
  six = 6,
  sept = 7,
  huit = 8,
  neuf = 9
}

function returnPeopleAndLength(people: string[] = ['Miles', 'Mick']): [string, number][] {
  return people.map((p: string) => { return [p, p.length]});
}

function displayPeopleAndLength(people?: string[], literal?: boolean): void {
  let peopleNL = returnPeopleAndLength(people);
  if (literal) {
    peopleNL = peopleNL.filter((p: [string, number]) => {return p[1] <= 9;});
  }

  for(const p of peopleNL) {
    console.log(`${p[0]} contient ${literal? NumberToString[p[1]] : p[1]} caractères`);
  }
}

export {returnPeopleAndLength, displayPeopleAndLength};