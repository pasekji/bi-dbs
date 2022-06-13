create or replace procedure SMAZ_VSECHNY_TABULKY AS
-- pokud v logu bude uvedeno, ze nektery objekt nebyl zrusen, protoze na nej jiny jeste existujici objekt stavi, spust proceduru opakovane, dokud se nezrusi vse
begin
  for iRec in 
    (select distinct OBJECT_TYPE, OBJECT_NAME,
      'drop '||OBJECT_TYPE||' "'||OBJECT_NAME||'"'||
      case OBJECT_TYPE when 'TABLE' then ' cascade constraints purge' else ' ' end as PRIKAZ
    from USER_OBJECTS where OBJECT_NAME not in ('SMAZ_VSECHNY_TABULKY', 'VYPNI_CIZI_KLICE', 'ZAPNI_CIZI_KLICE', 'VYMAZ_DATA_VSECH_TABULEK')
    ) loop
        begin
          dbms_output.put_line('Prikaz: '||irec.prikaz);
        execute immediate iRec.prikaz;
        exception
          when others then dbms_output.put_line('NEPOVEDLO SE!');
        end;
      end loop;
end;
/

create or replace procedure VYPNI_CIZI_KLICE as 
begin
  for cur in (select CONSTRAINT_NAME, TABLE_NAME from USER_CONSTRAINTS where CONSTRAINT_TYPE = 'R' ) 
  loop
    execute immediate 'alter table '||cur.TABLE_NAME||' modify constraint "'||cur.CONSTRAINT_NAME||'" DISABLE';
  end loop;
end VYPNI_CIZI_KLICE;
/


create or replace procedure ZAPNI_CIZI_KLICE as 
begin
  for cur in (select CONSTRAINT_NAME, TABLE_NAME from USER_CONSTRAINTS where CONSTRAINT_TYPE = 'R' ) 
  loop
    execute immediate 'alter table '||cur.TABLE_NAME||' modify constraint "'||cur.CONSTRAINT_NAME||'" enable validate';
  end loop;
end ZAPNI_CIZI_KLICE;
/

create or replace procedure VYMAZ_DATA_VSECH_TABULEK is
begin
  -- Vymazat data vsech tabulek
  VYPNI_CIZI_KLICE;
  for v_rec in (select distinct TABLE_NAME from USER_TABLES)
  loop
    execute immediate 'truncate table '||v_rec.TABLE_NAME||' drop storage';
  end loop;
  ZAPNI_CIZI_KLICE;
  
  -- Nastavit vsechny sekvence od 1
  for v_rec in (select distinct SEQUENCE_NAME  from USER_SEQUENCES)
  loop
    execute immediate 'alter sequence '||v_rec.SEQUENCE_NAME||' restart start with 1';
  end loop;
end VYMAZ_DATA_VSECH_TABULEK;
/


exec SMAZ_VSECHNY_TABULKY;


CREATE TABLE administrativa (
    neschopnost_index   NUMBER(5, 2) NOT NULL,
    oversleep_count     INTEGER NOT NULL,
    iq                  INTEGER,
    zamestnanec_key     INTEGER NOT NULL,
    oddeleni_key        INTEGER NOT NULL
);

ALTER TABLE administrativa ADD CONSTRAINT administrativa_pk PRIMARY KEY ( zamestnanec_key );

CREATE TABLE administrativa_vuz_rel (
    zamestnanec_key   INTEGER NOT NULL,
    vuz_key           INTEGER NOT NULL
);

ALTER TABLE administrativa_vuz_rel ADD CONSTRAINT administrativa_vuz_rel_pk PRIMARY KEY ( zamestnanec_key,
                                                                                          vuz_key );

CREATE TABLE dieta (
    dieta_key   INTEGER NOT NULL,
    cislo       INTEGER NOT NULL,
    poznamka    VARCHAR2(4000 CHAR)
);

ALTER TABLE dieta ADD CONSTRAINT dieta_pk PRIMARY KEY ( dieta_key );

ALTER TABLE dieta ADD CONSTRAINT dieta_cislo_un UNIQUE ( cislo );

CREATE TABLE kniha (
    kniha_key         INTEGER NOT NULL,
    kod               VARCHAR2(13 CHAR),
    jmeno             VARCHAR2(4000 CHAR) NOT NULL,
    autor             VARCHAR2(4000 CHAR) NOT NULL,
    zanr              VARCHAR2(4000 CHAR) NOT NULL,
    zamestnanec_key   INTEGER,
    pacient_key       INTEGER
);

ALTER TABLE kniha ADD CONSTRAINT kniha_pk PRIMARY KEY ( kniha_key );

ALTER TABLE kniha ADD CONSTRAINT kniha_kod_un UNIQUE ( kod );

CREATE TABLE lecba (
    lecba_key         INTEGER NOT NULL,
    nazev             VARCHAR2(4000 CHAR) NOT NULL,
    datum_realizace   DATE NOT NULL,
    kapacita          INTEGER NOT NULL,
    poznamka          VARCHAR2(4000 CHAR),
    zamestnanec_key   INTEGER NOT NULL,
    mistnost_key      INTEGER
);

ALTER TABLE lecba ADD CONSTRAINT lecba_pk PRIMARY KEY ( lecba_key );

CREATE TABLE medikament (
    medikament_key   INTEGER NOT NULL,
    jmeno            VARCHAR2(4000 CHAR) NOT NULL,
    skupina          VARCHAR2(4000 CHAR) NOT NULL,
    sila             NUMBER(5, 2) NOT NULL,
    dostupnost       INTEGER NOT NULL,
    poznamka         VARCHAR2(4000 CHAR)
);

ALTER TABLE medikament ADD CONSTRAINT medikament_pk PRIMARY KEY ( medikament_key );

ALTER TABLE medikament ADD CONSTRAINT medikament_jmeno_un UNIQUE ( jmeno );

CREATE TABLE medikament_zdravotnik_rel (
    medikament_key    INTEGER NOT NULL,
    zamestnanec_key   INTEGER NOT NULL
);

ALTER TABLE medikament_zdravotnik_rel ADD CONSTRAINT medikament_zdravotnik_rel_pk PRIMARY KEY ( medikament_key,
                                                                                                zamestnanec_key );

CREATE TABLE mistnost (
    mistnost_key   INTEGER NOT NULL,
    oznaceni       VARCHAR2(4 CHAR) NOT NULL,
    oddeleni_key   INTEGER NOT NULL
);

ALTER TABLE mistnost ADD CONSTRAINT mistnost_pk PRIMARY KEY ( mistnost_key );

ALTER TABLE mistnost ADD CONSTRAINT mistnost_oznaceni_un UNIQUE ( oznaceni );

CREATE TABLE navsteva (
    navsteva_key   INTEGER NOT NULL,
    datum          DATE NOT NULL,
    poznamka       VARCHAR2(4000 CHAR),
    pacient_key    INTEGER NOT NULL,
    mistnost_key   INTEGER NOT NULL
);

/*
CREATE UNIQUE INDEX navsteva__idx ON
    navsteva (
        pacient_key
    ASC );
*/

ALTER TABLE navsteva ADD CONSTRAINT navsteva_pk PRIMARY KEY ( navsteva_key );

CREATE TABLE navstevnik (
    navstevnik_key   INTEGER NOT NULL,
    osobni_cislo     INTEGER NOT NULL,
    jmeno            VARCHAR2(4000) NOT NULL,
    prijmeni         VARCHAR2(4000) NOT NULL,
    pocet_navstev    INTEGER NOT NULL,
    navsteva_key     INTEGER
);

ALTER TABLE navstevnik ADD CONSTRAINT navstevnik_pk PRIMARY KEY ( navstevnik_key );

ALTER TABLE navstevnik ADD CONSTRAINT navstevnik_osobni_cislo_un UNIQUE ( osobni_cislo );

CREATE TABLE oddeleni (
    oddeleni_key   INTEGER NOT NULL,
    cislo          INTEGER NOT NULL,
    diagnostika    VARCHAR2(4000 CHAR)
);

ALTER TABLE oddeleni ADD CONSTRAINT oddeleni_pk PRIMARY KEY ( oddeleni_key );

ALTER TABLE oddeleni ADD CONSTRAINT oddeleni_cislo_un UNIQUE ( cislo );

CREATE TABLE ordinace (
    nazev          VARCHAR2(4000 CHAR) NOT NULL,
    zemereni       VARCHAR2(4000 CHAR) NOT NULL,
    mistnost_key   INTEGER NOT NULL
);

ALTER TABLE ordinace ADD CONSTRAINT ordinace_pk PRIMARY KEY ( mistnost_key );

CREATE TABLE ozdravovna (
    ucel           VARCHAR2(4000 CHAR) NOT NULL,
    poznamka       VARCHAR2(4000 CHAR),
    mistnost_key   INTEGER NOT NULL
);

ALTER TABLE ozdravovna ADD CONSTRAINT ozdravovna_pk PRIMARY KEY ( mistnost_key );

CREATE TABLE pacient (
    pacient_key     INTEGER NOT NULL,
    osobni_cislo    INTEGER NOT NULL,
    jmeno           VARCHAR2(4000 CHAR) NOT NULL,
    prijmeni        VARCHAR2(4000 CHAR) NOT NULL,
    diagnoza        VARCHAR2(4000 CHAR) NOT NULL,
    hospitalizace   DATE NOT NULL,
    lecba_key       INTEGER NOT NULL,
    dieta_key       INTEGER NOT NULL,
    mistnost_key    INTEGER NOT NULL
);

ALTER TABLE pacient ADD CONSTRAINT pacient_pk PRIMARY KEY ( pacient_key );

ALTER TABLE pacient ADD CONSTRAINT pacient_osobni_cislo_un UNIQUE ( osobni_cislo );

CREATE TABLE pacient_medikament_rel (
    pacient_key      INTEGER NOT NULL,
    medikament_key   INTEGER NOT NULL
);

ALTER TABLE pacient_medikament_rel ADD CONSTRAINT pacient_medikament_rel_pk PRIMARY KEY ( pacient_key,
                                                                                          medikament_key );

CREATE TABLE pacientsky_pokoj (
    kapacita       INTEGER NOT NULL,
    poznamka       VARCHAR2(4000 CHAR),
    mistnost_key   INTEGER NOT NULL
);

ALTER TABLE pacientsky_pokoj ADD CONSTRAINT pacientsky_pokoj_pk PRIMARY KEY ( mistnost_key );

CREATE TABLE pocitac (
    pocitac_key       INTEGER NOT NULL,
    oznaceni          VARCHAR2(10 CHAR) NOT NULL,
    jmeno             VARCHAR2(4000 CHAR),
    ip_adresa         VARCHAR2(15 CHAR),
    mistnost_key      INTEGER,
    zamestnanec_key   INTEGER
);

CREATE UNIQUE INDEX pocitac__idx ON
    pocitac (
        zamestnanec_key
    ASC );

ALTER TABLE pocitac ADD CONSTRAINT pocitac_pk PRIMARY KEY ( pocitac_key );

ALTER TABLE pocitac ADD CONSTRAINT pocitac_oznaceni_un UNIQUE ( oznaceni );

CREATE TABLE pristroj (
    pristroj_key    INTEGER NOT NULL,
    oznaceni        VARCHAR2(10 CHAR) NOT NULL,
    nazev           VARCHAR2(4000 CHAR) NOT NULL,
    ucel            VARCHAR2(4000 CHAR) NOT NULL,
    hrozba_uroven   NUMBER(5, 2),
    mistnost_key    INTEGER
);

ALTER TABLE pristroj ADD CONSTRAINT pristroj_pk PRIMARY KEY ( pristroj_key );

ALTER TABLE pristroj ADD CONSTRAINT pristroj_oznaceni_un UNIQUE ( oznaceni );

CREATE TABLE procedura (
    popis            VARCHAR2(4000 CHAR) NOT NULL,
    uroven_bolesti   NUMBER(5, 2),
    lecba_key        INTEGER NOT NULL
);

ALTER TABLE procedura ADD CONSTRAINT procedura_pk PRIMARY KEY ( lecba_key );

CREATE TABLE terapie (
    typ         VARCHAR2(4000 CHAR) NOT NULL,
    ucinnost    NUMBER(5, 2),
    lecba_key   INTEGER NOT NULL
);

ALTER TABLE terapie ADD CONSTRAINT terapie_pk PRIMARY KEY ( lecba_key );

CREATE TABLE vuz (
    vuz_key        INTEGER NOT NULL,
    spz            VARCHAR2(8 CHAR) NOT NULL,
    ucel           VARCHAR2(4000 CHAR) NOT NULL,
    nazev          VARCHAR2(4000 CHAR),
    oddeleni_key   INTEGER NOT NULL
);

ALTER TABLE vuz ADD CONSTRAINT vuz_pk PRIMARY KEY ( vuz_key );

ALTER TABLE vuz ADD CONSTRAINT vuz_spz_un UNIQUE ( spz );

CREATE TABLE zamestnanec (
    zamestnanec_key   INTEGER NOT NULL,
    osobni_cislo      INTEGER NOT NULL,
    jmeno             VARCHAR2(4000 CHAR) NOT NULL,
    prijmeni          VARCHAR2(4000 CHAR) NOT NULL,
    pozice            VARCHAR2(4000 CHAR) NOT NULL,
    pocatek_pomeru    DATE NOT NULL,
    pocitac_key       INTEGER
);


CREATE UNIQUE INDEX zamestnanec__idx ON
    zamestnanec (
        pocitac_key
    ASC );

ALTER TABLE zamestnanec ADD CONSTRAINT zamestnanec_pk PRIMARY KEY ( zamestnanec_key );

ALTER TABLE zamestnanec ADD CONSTRAINT zamestnanec_osobni_cislo_un UNIQUE ( osobni_cislo );

CREATE TABLE zdravotnik (
    specializace              VARCHAR2(4000 CHAR) NOT NULL,
    praxe                     VARCHAR2(4000 CHAR) NOT NULL,
    resurrect_count           INTEGER NOT NULL,
    death_count               INTEGER NOT NULL,
    zamestnanec_key           INTEGER NOT NULL,
    ordinace_mistnost_key     INTEGER,
    ozdravovna_mistnost_key   INTEGER
);

ALTER TABLE zdravotnik ADD CONSTRAINT zdravotnik_pk PRIMARY KEY ( zamestnanec_key );

CREATE TABLE zdravotnik_pacient_rel (
    zamestnanec_key   INTEGER NOT NULL,
    pacient_key       INTEGER NOT NULL
);

ALTER TABLE zdravotnik_pacient_rel ADD CONSTRAINT zdravotnik_pacient_rel_pk PRIMARY KEY ( zamestnanec_key,
                                                                                          pacient_key );

ALTER TABLE administrativa
    ADD CONSTRAINT administrativa_oddeleni_fk FOREIGN KEY ( oddeleni_key )
        REFERENCES oddeleni ( oddeleni_key );

ALTER TABLE administrativa
    ADD CONSTRAINT administrativa_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE administrativa_vuz_rel
    ADD CONSTRAINT administrativavuzrel_adm_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES administrativa ( zamestnanec_key );

ALTER TABLE administrativa_vuz_rel
    ADD CONSTRAINT administrativavuzrel_vuz_fk FOREIGN KEY ( vuz_key )
        REFERENCES vuz ( vuz_key );

ALTER TABLE kniha
    ADD CONSTRAINT kniha_pacient_fk FOREIGN KEY ( pacient_key )
        REFERENCES pacient ( pacient_key );

ALTER TABLE kniha
    ADD CONSTRAINT kniha_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE lecba
    ADD CONSTRAINT lecba_ozdravovna_fk FOREIGN KEY ( mistnost_key )
        REFERENCES ozdravovna ( mistnost_key );

ALTER TABLE lecba
    ADD CONSTRAINT lecba_zdravotnik_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zdravotnik ( zamestnanec_key );

ALTER TABLE medikament_zdravotnik_rel
    ADD CONSTRAINT medikamentzdravotnikrel_med_fk FOREIGN KEY ( medikament_key )
        REFERENCES medikament ( medikament_key );

ALTER TABLE medikament_zdravotnik_rel
    ADD CONSTRAINT medikamentzdravotnikrel_zdr_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zdravotnik ( zamestnanec_key );

ALTER TABLE mistnost
    ADD CONSTRAINT mistnost_oddeleni_fk FOREIGN KEY ( oddeleni_key )
        REFERENCES oddeleni ( oddeleni_key );

ALTER TABLE navsteva
    ADD CONSTRAINT navsteva_pacient_fk FOREIGN KEY ( pacient_key )
        REFERENCES pacient ( pacient_key );

ALTER TABLE navsteva
    ADD CONSTRAINT navsteva_pacientsky_pokoj_fk FOREIGN KEY ( mistnost_key )
        REFERENCES pacientsky_pokoj ( mistnost_key );

ALTER TABLE navstevnik
    ADD CONSTRAINT navstevnik_navsteva_fk FOREIGN KEY ( navsteva_key )
        REFERENCES navsteva ( navsteva_key );

ALTER TABLE ordinace
    ADD CONSTRAINT ordinace_mistnost_fk FOREIGN KEY ( mistnost_key )
        REFERENCES mistnost ( mistnost_key );

ALTER TABLE ozdravovna
    ADD CONSTRAINT ozdravovna_mistnost_fk FOREIGN KEY ( mistnost_key )
        REFERENCES mistnost ( mistnost_key );

ALTER TABLE pacient
    ADD CONSTRAINT pacient_dieta_fk FOREIGN KEY ( dieta_key )
        REFERENCES dieta ( dieta_key );

ALTER TABLE pacient
    ADD CONSTRAINT pacient_lecba_fk FOREIGN KEY ( lecba_key )
        REFERENCES lecba ( lecba_key );

ALTER TABLE pacient
    ADD CONSTRAINT pacient_pacientsky_pokoj_fk FOREIGN KEY ( mistnost_key )
        REFERENCES pacientsky_pokoj ( mistnost_key );

ALTER TABLE pacient_medikament_rel
    ADD CONSTRAINT pacientmedikamentrel_med_fk FOREIGN KEY ( medikament_key )
        REFERENCES medikament ( medikament_key );

ALTER TABLE pacient_medikament_rel
    ADD CONSTRAINT pacientmedikamentrel_pac_fk FOREIGN KEY ( pacient_key )
        REFERENCES pacient ( pacient_key );

ALTER TABLE pacientsky_pokoj
    ADD CONSTRAINT pacientsky_pokoj_mistnost_fk FOREIGN KEY ( mistnost_key )
        REFERENCES mistnost ( mistnost_key );

ALTER TABLE pocitac
    ADD CONSTRAINT pocitac_ordinace_fk FOREIGN KEY ( mistnost_key )
        REFERENCES ordinace ( mistnost_key );

ALTER TABLE pocitac
    ADD CONSTRAINT pocitac_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE pristroj
    ADD CONSTRAINT pristroj_ozdravovna_fk FOREIGN KEY ( mistnost_key )
        REFERENCES ozdravovna ( mistnost_key );

ALTER TABLE procedura
    ADD CONSTRAINT procedura_lecba_fk FOREIGN KEY ( lecba_key )
        REFERENCES lecba ( lecba_key );

ALTER TABLE terapie
    ADD CONSTRAINT terapie_lecba_fk FOREIGN KEY ( lecba_key )
        REFERENCES lecba ( lecba_key );

ALTER TABLE vuz
    ADD CONSTRAINT vuz_oddeleni_fk FOREIGN KEY ( oddeleni_key )
        REFERENCES oddeleni ( oddeleni_key );

ALTER TABLE zamestnanec
    ADD CONSTRAINT zamestnanec_pocitac_fk FOREIGN KEY ( pocitac_key )
        REFERENCES pocitac ( pocitac_key );

ALTER TABLE zdravotnik
    ADD CONSTRAINT zdravotnik_ordinace_fk FOREIGN KEY ( ordinace_mistnost_key )
        REFERENCES ordinace ( mistnost_key );

ALTER TABLE zdravotnik
    ADD CONSTRAINT zdravotnik_ozdravovna_fk FOREIGN KEY ( ozdravovna_mistnost_key )
        REFERENCES ozdravovna ( mistnost_key );

ALTER TABLE zdravotnik
    ADD CONSTRAINT zdravotnik_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE zdravotnik_pacient_rel
    ADD CONSTRAINT zdravotnikpacientrel_pac_fk FOREIGN KEY ( pacient_key )
        REFERENCES pacient ( pacient_key );

ALTER TABLE zdravotnik_pacient_rel
    ADD CONSTRAINT zdravotnikpacientrel_zdr_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zdravotnik ( zamestnanec_key );
        