import Album from "./Album";
import { JazzMusician } from "./JazzMusician";
import log from "./Log";
import { RockStar } from "./RockStar";

log("Bienvenue dans ma première application TypeScript.");

const musicians = [new JazzMusician("Dude", "Jaa", 23), new RockStar("Mister", "AZa", 12)];

musicians[0].addAlbum(new Album("Rooock"));
musicians[0].addAlbum(new Album("Jazzzz"));


for(const musician of musicians) {
  console.log(musician.toString());
  console.log("Albums:");
  for(const album of musician.albums) {
    console.log(` - ${album.toString()}`);
  }
  if(musician instanceof JazzMusician) {
    musician.swing();
  } else if(musician instanceof RockStar) {
    musician.shout();
  }
}

// Run with : npx ts-node src/tp4.ts