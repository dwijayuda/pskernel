import { access, readFile } from "node:fs/promises";

const root=new URL("../",import.meta.url);
const profile=JSON.parse(await readFile(
  new URL("contracts/archive/ARCHIVE_PROFILE_V0.json",root),
  "utf8",
));
if(profile.contract!=="psc-archive-profile/0"||profile.offlineVerificationRequired!==true){
  throw new Error("PSC_ARCHIVE_PROFILE");
}
for(const relative of [...profile.requiredRepositoryObjects,...profile.knowledgeObjects]){
  await access(new URL(relative,root));
}
if(profile.hashAgility?.required!==true) throw new Error("PSC_ARCHIVE_HASH_AGILITY");
process.stdout.write(
  "PSCV_ARCHIVE_PROFILE: PASS ("+
  String(profile.requiredRepositoryObjects.length+profile.knowledgeObjects.length)+
  " required objects)\n",
);
