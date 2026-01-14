import log from './Log';

interface ElementToString {
  toString(): string;
}

function display<T extends ElementToString>(list: T[]): void {
  for(const e of list) {
    log(e.toString());
  }
}

export default display;