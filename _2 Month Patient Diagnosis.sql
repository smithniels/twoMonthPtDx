-- The only code that needs to be editted before this is run is the deceased section. 
--The other 4 sections automatically pull from 2 months ago to today

--***********************************************************************************************************************************
--Patients Who've Passed (Deceased)
--***********************************************************************************************************************************\

select distinct p.controlNo AS Deceased, u.uFname, u.uLname, u.dob, u.sex, p.deceasedDate

from patients p,users u

where p.pid=u.uid
   and p.deceasedDate <> ''
   																		   --     ATTN: This is the one thing that needs to be adjusted
   and (p.deceaseddate like '10/%/2019' or p.deceaseddate like '11/%/2019') -- <--~~--~~--~~ EDIT THESE 2 BAD BOYS (LAST MONTH + CURRENT MONTH) 
																		   --     ATTN: This is the one thing that needs to be adjusted
ORDER BY  p.deceasedDate DESC

--	  these aren't actually stored as dates,
--    so we can't just do a 'between' that would be too easy...
--	  It's formatted as a data type [text field], which is a deprecated format that's hard to work with.

--***********************************************************************************************************************************
--Cancer Diagnosises
--***********************************************************************************************************************************

if object_id ('tempdb..#temptable1') IS NOT NULL DROP TABLE #temptable1
if object_id ('tempdb..#temptable2') IS NOT NULL DROP TABLE #temptable2

select p.controlNo, u.uFname, u.uLname,e.date, i.itemName, id.value

into #temptable1

from patients p, users u, doctors d, enc e
   left join diagnosis dx		on e.encounterid=dx.encounterid
   left join items i			on dx.itemid=i.itemid
   left join itemdetail id		on i.itemid=id.itemid

where p.pid=e.patientid
  and p.doctorid=d.doctorid
  and u.uid=p.pid
  and (id.value like 'c%' or id.value like 'd0%' or id.value like 'd1%' or 
	   id.value like  'd2%' or id.value like 'd3%' or id.value like 'd4%')

order by p.controlno, u.ufname, u.ulname,e.date, i.itemname, id.value

-- select most recent dx date per pat per ICD code
select distinct t.controlno as cancer, t.ufname, t.ulname, convert(date,t.date) as minDate, t.itemName, t.value

into #temptable2

from #temptable1 t
		inner join (
			select controlno, min(date) date
			from #temptable1
			group by controlno, value
		) b on t.controlno=b.controlno and t.date=b.date

select * from #temptable2
where minDate between DATEADD(M,-2,getdate()) and GETDATE() 

--***********************************************************************************************************************************
--Chlamydia/Gonorrhea
--***********************************************************************************************************************************

select p.controlno as Chlamydia_Gonorrhea, u.uFname, u.uLname, u.dob, u.sex, e.encounterId, convert(date,e.date) as date , 
	   e.visitType, d.printName, convert(varchar,i.itemid) as itemId, i.itemname as Description, ld.result

from patients p, users u, enc e, doctors d, items i, labdata ld

where p.pid=u.uid
  and u.uid=e.patientid
  and e.doctorid=d.doctorid
  and e.encounterid=ld.encounterid
  and ld.itemid=i.itemid
  and ld.deleteflag='0'
  and e.date between DATEADD(M,-2,getdate()) and GETDATE() 
  and (i.itemname like 'L-GC%' 
    or i.itemname like '%Ct-NG%'
    or i.itemname like 'L-pap%'
    or i.itemname like 'l-ch%')
  and ld.result <> ''
  and ld.result not like '%neg%'
  and ld.result not like 'no%'
  and ld.result not like 'nea%'

order by ld.result

--***********************************************************************************************************************************
-- HIV
--***********************************************************************************************************************************

select p.controlno as HIV, p.pid, u.uFname, u.uLname, u.ptDob, u.sex, 
	   e.encounterId, convert(varchar,e.date,103) as visitDate, e.visitType, d.printName, i.itemId, i.itemName, ld.result,ld.itemId

from patients p, users u, enc e, doctors d, items i, labdata ld

where p.pid=u.uid
  and u.uid=e.patientid
  and e.doctorid=d.doctorid
  and e.encounterid=ld.encounterid
  and ld.itemid=i.itemid
  and ld.deleteflag='0'
  and e.date between DATEADD(M,-2,getdate()) and GETDATE() 
  and i.itemname like '%HIV%'
  and ld.result like 'Positive%'
  and ld.itemid in ('290543')

--***********************************************************************************************************************************
--Pregnancy
--***********************************************************************************************************************************

select p.controlno as Pregnancy, p.controlno, u.uFname, u.uLname, convert(varchar,u.ptdob,101) as dob, convert(date,e.date) as date, 
       i.itemName, l.result

from patients p, users u, enc e
  left join labdata l			 on e.encounterid=l.encounterid
  left join labdatadetail ldd	 on ldd.reportid=l.reportid
  left join items i			 on l.itemid=i.itemid

where p.pid=u.uid
  and e.patientid=u.uid
  and e.date between DATEADD(M,-2,getdate()) and GETDATE()
  and i.itemname like ('urine%')
  AND l.result like 'pos%'
  and l.deleteflag='0'

order by p.controlno, e.date desc
