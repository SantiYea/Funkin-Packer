import * as en from "./languages/en.json";
import * as ar from "./languages/ar.json";
import * as de from "./languages/de.json";
import * as es from "./languages/es.json";
import * as ca_fr from "./languages/ca-fr.json";
import * as hi from "./languages/hi.json";
import * as it from "./languages/it.json";
import * as pt_br from "./languages/pt-br.json";
import * as tr from "./languages/tr.json";
import * as uk from "./languages/uk.json";
import * as ru from "./languages/ru.json";
import * as zh_cn from "./languages/zh-cn.json";
import * as zh_tw from "./languages/zh-tw.json";

export type Language = {
  lang: string;
  name: string;
  mapping: Record<string, string>;
  isRtl?: boolean;
};

export function getLanguageByCode(code: string): Language {
  for (const item of languages) {
    if (item.lang === code) return item;
  }
  return languages[0];
}

export const languages: Language[] = [
  { lang: "en", name: "english", mapping: en },
  { lang: "ar", name: "العربية", mapping: ar, isRtl: false }, // by @KarimAkra
  { lang: "zh-cn", name: "简体中文", mapping: zh_cn },
  { lang: "zh-tw", name: "繁體中文", mapping: zh_tw },
  { lang: "de", name: "deutsch", mapping: de },
  { lang: "es", name: "español", mapping: es },
  { lang: "ca-fr", name: "français (canadien)", mapping: ca_fr }, // by @thatoneidiotxav
  { lang: "hi", name: "हिन्दी", mapping: hi },
  { lang: "it", name: "italiano", mapping: it }, // by @NexIsDumb
  { lang: "pt-br", name: "português (brasil)", mapping: pt_br }, // by @CrowPlexus
  { lang: "tr", name: "türkçe", mapping: tr }, // by @HomuHomu833 and @ArkoseLabsOfficial
  { lang: "uk", name: "українська", mapping: uk }, // by @mrchaoss1
  { lang: "ru", name: "русский", mapping: ru }, // by @mrchaoss1
] as const;

const ALL_KEYS = Object.keys(languages[0].mapping);

if (DEBUG) {
  for (const item of languages) {
    for (const key of ALL_KEYS) {
      if (!item.mapping[key]) {
        console.warn(`Missing key in language ${item.lang}.json: ${key}`);
      }
    }
  }
}
