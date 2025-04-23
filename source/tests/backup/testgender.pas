unit testGender;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry;

type

    { TTestGender }

    TTestGender= class(TTestCase)
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published
        // English tests
        procedure TestInitGenderEN;
        procedure TestListMasculineGenders;
        procedure TestListFeminineGenders;
        procedure TestListMasculinePronouns;
        procedure TestListFemininePronouns;
        procedure TestListMasculineTitles;
        procedure TestListFeminineTitles;

        // German tests
        procedure TestInitGenderDE;
        procedure TestListMasculineGendersDE;
        procedure TestListFeminineGendersDE;
        procedure TestListMasculinePronounsDE;
        procedure TestListFemininePronounsDE;
        procedure TestListMasculineTitlesDE;
        procedure TestListFeminineTitlesDE;

        // French tests
        procedure TestInitGenderFR;
        procedure TestListMasculineGendersFR;
        procedure TestListFeminineGendersFR;
        procedure TestListMasculinePronounsFR;
        procedure TestListFemininePronounsFR;
        procedure TestListMasculineTitlesFR;
        procedure TestListFeminineTitlesFR;

        // Spanish tests
        procedure TestInitGenderES;
        procedure TestListMasculineGendersES;
        procedure TestListFeminineGendersES;
        procedure TestListMasculinePronounsES;
        procedure TestListFemininePronounsES;
        procedure TestListMasculineTitlesES;
        procedure TestListFeminineTitlesES;

        // Italian tests
        procedure TestInitGenderIT;
        procedure TestListMasculineGendersIT;
        procedure TestListFeminineGendersIT;
        procedure TestListMasculinePronounsIT;
        procedure TestListFemininePronounsIT;
        procedure TestListMasculineTitlesIT;
        procedure TestListFeminineTitlesIT;

        // Dutch tests
        procedure TestInitGenderNL;
        procedure TestListMasculineGendersNL;
        procedure TestListFeminineGendersNL;
        procedure TestListMasculinePronounsNL;
        procedure TestListFemininePronounsNL;
        procedure TestListMasculineTitlesNL;
        procedure TestListFeminineTitlesNL;

        // Chinese tests
        procedure TestInitGenderZH;
        procedure TestListMasculineGendersZH;
        procedure TestListFeminineGendersZH;
        procedure TestListMasculinePronounsZH;
        procedure TestListFemininePronounsZH;
        procedure TestListMasculineTitlesZH;
        procedure TestListFeminineTitlesZH;

        // Japanese tests
        procedure TestInitGenderJA;
        procedure TestListMasculineGendersJA;
        procedure TestListFeminineGendersJA;
        procedure TestListMasculinePronounsJA;
        procedure TestListFemininePronounsJA;
        procedure TestListMasculineTitlesJA;
        procedure TestListFeminineTitlesJA;

        // Korean tests
        procedure TestInitGenderKO;
        procedure TestListMasculineGendersKO;
        procedure TestListFeminineGendersKO;
        procedure TestListMasculinePronounsKO;
        procedure TestListFemininePronounsKO;
        procedure TestListMasculineTitlesKO;
        procedure TestListFeminineTitlesKO;

        // Arabic tests
        procedure TestInitGenderAR;
        procedure TestListMasculineGendersAR;
        procedure TestListFeminineGendersAR;
        procedure TestListMasculinePronounsAR;
        procedure TestListFemininePronounsAR;
        procedure TestListMasculineTitlesAR;
        procedure TestListFeminineTitlesAR;

        // Russian tests
        procedure TestInitGenderRU;
        procedure TestListMasculineGendersRU;
        procedure TestListFeminineGendersRU;
        procedure TestListMasculinePronounsRU;
        procedure TestListFemininePronounsRU;
        procedure TestListMasculineTitlesRU;
        procedure TestListFeminineTitlesRU;

        // Hebrew tests
        procedure TestInitGenderHE;
        procedure TestListMasculineGendersHE;
        procedure TestListFeminineGendersHE;
        procedure TestListMasculinePronounsHE;
        procedure TestListFemininePronounsHE;
        procedure TestListMasculineTitlesHE;
        procedure TestListFeminineTitlesHE;

        // Ukrainian tests
        procedure TestInitGenderUK;
        procedure TestListMasculineGendersUK;
        procedure TestListFeminineGendersUK;
        procedure TestListMasculinePronounsUK;
        procedure TestListFemininePronounsUK;
        procedure TestListMasculineTitlesUK;
        procedure TestListFeminineTitlesUK;
    end;

implementation

uses
  sugar.gender, sugar.languages;

// Helper functions for language gender definitions
function gendersDE: TGenderDef;
begin
  Result := registerGenderDef(ISO693_German, @initGenderDefDE);
end;

function gendersFR: TGenderDef;
begin
  Result := registerGenderDef(ISO693_French, @initGenderDefFR);
end;

function gendersES: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Spanish, @initGenderDefES);
end;

function gendersIT: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Italian, @initGenderDefIT);
end;

function gendersNL: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Dutch, @initGenderDefNL);
end;

function gendersZH: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Chinese, @initGenderDefZH);
end;

function gendersJA: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Japanese, @initGenderDefJA);
end;

function gendersKO: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Korean, @initGenderDefKO);
end;

function gendersAR: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Arabic, @initGenderDefAR);
end;

function gendersRU: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Russian, @initGenderDefRU);
end;

function gendersHE: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Hebrew, @initGenderDefHE);
end;

function gendersUK: TGenderDef;
begin
  Result := registerGenderDef(ISO693_Ukrainian, @initGenderDefUK);
end;

procedure TTestGender.SetUp;
begin

end;

procedure TTestGender.TearDown;
begin

end;

// English Tests
procedure TTestGender.TestInitGenderEN;
begin
    Assert(assigned(gendersEN), 'genderDefEN is not assigned');
    Assert(length(gendersEn.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersEn.genderNames) = 8, Format('GenderNames is %d', [length(gendersEn.genderNames)]));
end;

procedure TTestGender.TestListMasculineGenders;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersEN.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Man'      : assert(true);
            'Male'     : assert(true);
            else          assert(false, _g + ' is not a masculine gender');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGenders;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersEN.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Woman'  : assert(true);
            'Female' : assert(true);
            else       assert(false, _g + ' is not a feminine gender');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronouns;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersEN.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            'He/Him' : ;
            else         assert(false, _g + ' is not a masculine pronoun');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronouns;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersEN.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            'She/Her': ;
            else          assert(false, _g + ' is not a Feminine pronoun');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitles;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersEN.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Mr': ;
            else      assert(false, _g + ' is not a Masculine title');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitles;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersEN.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Miss': ;
            'Mrs': ;
            'Ms': ;
            else      assert(false, _g + ' is not a Feminine title');
        end;
    end;
end;

// German Tests
procedure TTestGender.TestInitGenderDE;
begin
    Assert(assigned(gendersDE), 'genderDefDE is not assigned');
    Assert(length(gendersDE.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersDE.genderNames) = 8, Format('GenderNames is %d', [length(gendersDE.genderNames)]));
end;

procedure TTestGender.TestListMasculineGendersDE;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersDE.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Mann'      : assert(true);
            'Männlich'  : assert(true);
            else           assert(false, _g + ' is not a masculine gender in German');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGendersDE;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersDE.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Frau'     : assert(true);
            'Weiblich' : assert(true);
            else          assert(false, _g + ' is not a feminine gender in German');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronounsDE;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersDE.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Er/Ihm' : ;
            else         assert(false, _g + ' is not a masculine pronoun in German');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronounsDE;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersDE.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Sie/Ihr': ;
            else          assert(false, _g + ' is not a feminine pronoun in German');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitlesDE;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersDE.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Hr.': ;
            else      assert(false, _g + ' is not a masculine title in German');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitlesDE;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersDE.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Frl.': ;
            'Fr.': ;
            else      assert(false, _g + ' is not a feminine title in German');
        end;
    end;
end;

// French Tests
procedure TTestGender.TestInitGenderFR;
begin
    Assert(assigned(gendersFR), 'genderDefFR is not assigned');
    Assert(length(gendersFR.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersFR.genderNames) = 8, Format('GenderNames is %d', [length(gendersFR.genderNames)]));
end;

procedure TTestGender.TestListMasculineGendersFR;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersFR.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Homme'    : assert(true);
            'Masculin' : assert(true);
            else          assert(false, _g + ' is not a masculine gender in French');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGendersFR;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersFR.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Femme'    : assert(true);
            'Féminin'  : assert(true);
            else          assert(false, _g + ' is not a feminine gender in French');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronounsFR;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersFR.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Il/Lui' : ;
            else         assert(false, _g + ' is not a masculine pronoun in French');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronounsFR;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersFR.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Elle/La': ;
            else          assert(false, _g + ' is not a feminine pronoun in French');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitlesFR;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersFR.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            'M.': ;
            else      assert(false, _g + ' is not a masculine title in French');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitlesFR;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersFR.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Mlle': ;
            'Mme': ;
            else      assert(false, _g + ' is not a feminine title in French');
        end;
    end;
end;

// Spanish Tests
procedure TTestGender.TestInitGenderES;
begin
    Assert(assigned(gendersES), 'genderDefES is not assigned');
    Assert(length(gendersES.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersES.genderNames) = 8, Format('GenderNames is %d', [length(gendersES.genderNames)]));
end;

procedure TTestGender.TestListMasculineGendersES;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersES.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Hombre'    : assert(true);
            'Masculino' : assert(true);
            else           assert(false, _g + ' is not a masculine gender in Spanish');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGendersES;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersES.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Mujer'     : assert(true);
            'Femenino'  : assert(true);
            else           assert(false, _g + ' is not a feminine gender in Spanish');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronounsES;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersES.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Él/Lo' : ;
            else        assert(false, _g + ' is not a masculine pronoun in Spanish');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronounsES;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersES.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Ella/La': ;
            else          assert(false, _g + ' is not a feminine pronoun in Spanish');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitlesES;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersES.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Sr.': ;
            else      assert(false, _g + ' is not a masculine title in Spanish');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitlesES;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersES.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Srta.': ;
            'Sra.': ;
            else       assert(false, _g + ' is not a feminine title in Spanish');
        end;
    end;
end;

// Italian Tests
procedure TTestGender.TestInitGenderIT;
begin
    Assert(assigned(gendersIT), 'genderDefIT is not assigned');
    Assert(length(gendersIT.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersIT.genderNames) = 8, Format('GenderNames is %d', [length(gendersIT.genderNames)]));
end;

procedure TTestGender.TestListMasculineGendersIT;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersIT.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Uomo'     : assert(true);
            'Maschile' : assert(true);
            else          assert(false, _g + ' is not a masculine gender in Italian');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGendersIT;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersIT.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Donna'      : assert(true);
            'Femminile'  : assert(true);
            else            assert(false, _g + ' is not a feminine gender in Italian');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronounsIT;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersIT.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Lui/Lo' : ;
            else         assert(false, _g + ' is not a masculine pronoun in Italian');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronounsIT;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersIT.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Lei/La': ;
            else         assert(false, _g + ' is not a feminine pronoun in Italian');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitlesIT;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersIT.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Sig.': ;
            else       assert(false, _g + ' is not a masculine title in Italian');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitlesIT;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersIT.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Sig.na': ;
            'Sig.ra': ;
            else         assert(false, _g + ' is not a feminine title in Italian');
        end;
    end;
end;

// Dutch Tests
procedure TTestGender.TestInitGenderNL;
begin
    Assert(assigned(gendersNL), 'genderDefNL is not assigned');
    Assert(length(gendersNL.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersNL.genderNames) = 8, Format('GenderNames is %d', [length(gendersNL.genderNames)]));
end;

procedure TTestGender.TestListMasculineGendersNL;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersNL.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Man'       : assert(true);
            'Mannelijk' : assert(true);
            else           assert(false, _g + ' is not a masculine gender in Dutch');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGendersNL;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersNL.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Vrouw'      : assert(true);
            'Vrouwelijk' : assert(true);
            else            assert(false, _g + ' is not a feminine gender in Dutch');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronounsNL;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersNL.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Hij/Hem' : ;
            else          assert(false, _g + ' is not a masculine pronoun in Dutch');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronounsNL;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersNL.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Zij/Haar': ;
            else          assert(false, _g + ' is not a feminine pronoun in Dutch');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitlesNL;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersNL.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            'Dhr.': ;
            else       assert(false, _g + ' is not a masculine title in Dutch');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitlesNL;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersNL.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            'Mej.': ;
            'Mevr.': ;
            else        assert(false, _g + ' is not a feminine title in Dutch');
        end;
    end;
end;

// Chinese Tests
procedure TTestGender.TestInitGenderZH;
begin
    Assert(assigned(gendersZH), 'genderDefZH is not assigned');
    Assert(length(gendersZH.genderNames) <> 0, 'GenderNames is empty');
    Assert(length(gendersZH.genderNames) = 8, Format('GenderNames is %d', [length(gendersZH.genderNames)]));
end;

procedure TTestGender.TestListMasculineGendersZH;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersZH.genderNames(genderMasculine);
    for _g in _genders do begin
        case _g of
            '男性' : assert(true);
            '男'   : assert(true);
            else      assert(false, _g + ' is not a masculine gender in Chinese');
        end;
    end;
end;

procedure TTestGender.TestListFeminineGendersZH;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersZH.genderNames(genderFeminine);
    for _g in _genders do begin
        case _g of
            '女性' : assert(true);
            '女'   : assert(true);
            else      assert(false, _g + ' is not a feminine gender in Chinese');
        end;
    end;
end;

procedure TTestGender.TestListMasculinePronounsZH;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersZH.genderPronouns(genderMasculine);
    for _g in _genders do begin
        case _g of
            '他/他的' : ;
            else          assert(false, _g + ' is not a masculine pronoun in Chinese');
        end;
    end;
end;

procedure TTestGender.TestListFemininePronounsZH;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersZH.genderPronouns(genderFeminine);
    for _g in _genders do begin
        case _g of
            '她/她的': ;
            else          assert(false, _g + ' is not a feminine pronoun in Chinese');
        end;
    end;
end;

procedure TTestGender.TestListMasculineTitlesZH;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersZH.genderTitles(genderMasculine);
    for _g in _genders do begin
        case _g of
            '先生': ;
            else       assert(false, _g + ' is not a masculine title in Chinese');
        end;
    end;
end;

procedure TTestGender.TestListFeminineTitlesZH;
var
    _genders: TStringArray;
    _g: String;
begin
    _genders := gendersZH.genderTitles(genderFeminine);
    for _g in _genders do begin
        case _g of
            '小姐': ;
            '女士': ;
            else       assert(false, _g + ' is not a feminine title in Chinese');
        end;
    end;
end;

// Japanese Tests
procedure TTestGender.TestInitGenderJA;
begin

end;

procedure TTestGender.TestListMasculineGendersJA;
begin

end;

procedure TTestGender.TestListFeminineGendersJA;
begin

end;

procedure TTestGender.TestListMasculinePronounsJA;
begin

end;

procedure TTestGender.TestListFemininePronounsJA;
begin

end;

procedure TTestGender.TestListMasculineTitlesJA;
begin

end;

procedure TTestGender.TestListFeminineTitlesJA;
begin

end;

procedure TTestGender.TestInitGenderKO;
begin

end;

procedure TTestGender.TestListMasculineGendersKO;
begin

end;

procedure TTestGender.TestListFeminineGendersKO;
begin

end;

procedure TTestGender.TestListMasculinePronounsKO;
begin

end;

procedure TTestGender.TestListFemininePronounsKO;
begin

end;

procedure TTestGender.TestListMasculineTitlesKO;
begin

end;

procedure TTestGender.TestListFeminineTitlesKO;
begin

end;

procedure TTestGender.TestInitGenderAR;
begin

end;

procedure TTestGender.TestListMasculineGendersAR;
begin

end;

procedure TTestGender.TestListFeminineGendersAR;
begin

end;

procedure TTestGender.TestListMasculinePronounsAR;
begin

end;

procedure TTestGender.TestListFemininePronounsAR;
begin

end;

procedure TTestGender.TestListMasculineTitlesAR;
begin

end;

procedure TTestGender.TestListFeminineTitlesAR;
begin

end;

procedure TTestGender.TestInitGenderRU;
begin

end;

procedure TTestGender.TestListMasculineGendersRU;
begin

end;

procedure TTestGender.TestListFeminineGendersRU;
begin

end;

procedure TTestGender.TestListMasculinePronounsRU;
begin

end;

procedure TTestGender.TestListFemininePronounsRU;
begin

end;

procedure TTestGender.TestListMasculineTitlesRU;
begin

end;

procedure TTestGender.TestListFeminineTitlesRU;
begin

end;

procedure TTestGender.TestInitGenderHE;
begin

end;

procedure TTestGender.TestListMasculineGendersHE;
begin

end;

procedure TTestGender.TestListFeminineGendersHE;
begin

end;

procedure TTestGender.TestListMasculinePronounsHE;
begin

end;

procedure TTestGender.TestListFemininePronounsHE;
begin

end;

procedure TTestGender.TestListMasculineTitlesHE;
begin

end;

procedure TTestGender.TestListFeminineTitlesHE;
begin

end;

procedure TTestGender.TestInitGenderUK;
begin

end;

procedure TTestGender.TestListMasculineGendersUK;
begin

end;

procedure TTestGender.TestListFeminineGendersUK;
begin

end;

procedure TTestGender.TestListMasculinePronounsUK;
begin

end;

procedure TTestGender.TestListFemininePronounsUK;
begin

end;

procedure TTestGender.TestListMasculineTitlesUK;
begin

end;

procedure TTestGender.TestListFeminineTitlesUK;
begin

end;

initialization

    RegisterTest(TTestGender);
end.

