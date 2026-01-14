import log from "./Log";
import { Musician } from "./Musician";
import { Music } from "./Utils";

export class RockStar extends Musician {
  constructor(firstName: string, lastName: string, age: number) {
    super(firstName, lastName, age, Music.ROCK);
  }

  public shout(): void {
    log("I'm shouting!");
  }
}

