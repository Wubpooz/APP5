export default class Album {
  public readonly title: string;

  constructor(title: string) {
    this.title = title;
  }

  public toString(): string {
    return this.title;
  }
}