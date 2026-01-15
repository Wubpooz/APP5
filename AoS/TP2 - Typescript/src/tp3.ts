enum Music {
  JAZZ = "JAZZ",
  ROCK = "ROCK"
};

interface ElementToString {
  toString(): string;
}

interface IMusician {
  addAlbum(album: Album): void;
}

class Album {
  public readonly title: string;

  constructor(title: string) {
    this.title = title;
  }

  public toString(): string {
    return this.title;
  }
}

class Musician implements IMusician {
  private _firstName!: string;
  private _lastName!: string;
  private _age!: number;
  private _style: Music|undefined;
  private _albums: Album[] = [];

  constructor(firstName: string, lastName: string, age: number, style?: Music) {
    this._firstName = firstName;
    this._lastName = lastName;
    this._age = age;
    this._style = style;
  }

  public addAlbum(album: Album): void {
    this._albums.push(album);
  }

  public toString(): string {
    if(this._style) {
      return `${this.firstName} ${this._lastName} plays ${this._style}`;
    }
    return `${this.firstName} ${this._lastName}`;
  }

  public get firstName() : string {
    return this._firstName;
  }
  public set firstName(name: string) {
    this._firstName = name;
  }

  public get lastName() : string {
    return this._lastName;
  }
  public set lastName(name: string) {
    this._lastName = name;
  }

  public get age() : number {
    return this._age;
  }
  public set age(age: number) {
    this._age = age;
  }

  public get style() : Music|undefined {
    return this._style;
  }
  public set style(style: Music) {
    this._style = style;
  }

  public get albums(): Album[] {
    return this._albums;
  }

  public set albums(albums: Album[]) {
    this._albums = albums;
  }
}


class JazzMusician extends Musician {
  constructor(firstName: string, lastName: string, age: number) {
    super(firstName, lastName, age, Music.JAZZ);
  }
}

class RockStar extends Musician {
  constructor(firstName: string, lastName: string, age: number) {
    super(firstName, lastName, age, Music.ROCK);
  }
}

function display<T extends ElementToString>(list: T[]): void {
  for(const e of list) {
    console.log(e.toString());
  }
}

export { Music, Album, Musician, JazzMusician, RockStar, display };