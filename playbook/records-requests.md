# Records requests (drafts only; Nick sends, nothing has been sent)

## DC Health: food establishment inspections as data (Nick, 2026-10-27: "Records request first")

DC Health inspects pass/fail and gives no grade, score or placard. Its reports are only in the search at dc.healthinspections.us (one
HTML report per inspection, a rolling three years, no bulk file, API or Open Data DC dataset). Nick chose to ask for the records before
anyone crawls that search, so until data arrives the app and site only link it.

How it's sent: DC Health's Open Government page (dchealth.dc.gov/node/285602, read 2026-10-27) says FOIA requests go through the DC
government's Public FOIA Portal, myfoia.dc.gov, choosing DC Health as the agency; mail, fax and email are also accepted, and the page
names DC Health's FOIA Officer at 2201 Shannon Place SE, 4th Floor, Washington, DC 20020. Nick files it from his own portal account.
The page states no fees or response time; the draft asks for a fee waiver and an estimate before any fee. (D.C. Code § 2-532(c) is
generally read as 15 business days, extendable by 10: not checked here, so confirm on foia.dc.gov before counting on it.)

> Agency: DC Health (Department of Health)
> Subject: Food establishment inspection records, as a spreadsheet
>
> Hello,
>
> Under the DC Freedom of Information Act, I'd like the records of DC Health's food establishment inspections from January 1, 2023
> to the date the request is processed, in an electronic format such as a spreadsheet or CSV export from the inspection system (not
> scanned reports), with these fields where the system holds them:
>
> - the establishment's name as inspected and its premises address, ward and establishment type
> - its DC Health license or establishment number, and its DLCP business license number if recorded
> - each inspection's date and type (routine, follow-up, complaint, pre-operational and so on) and its risk category
> - the number of Priority, Priority Foundation and Core violations, and how many were corrected on site or repeated
> - any closure ordered at that inspection, and the date the establishment was cleared to reopen
>
> I don't need inspectors' names, owners' or license holders' names, phone numbers, email addresses or any other personal information,
> and those can be left out. If the full violation text is easy to include, it's welcome, but the counts above are the core of the
> request.
>
> I build a free restaurant guide for Washington, DC (DC Eats) that links each place to DC Health's inspection search. The records would
> let it show each place's latest inspection date and violation counts as DC Health records them, credited to DC Health. Because the
> purpose is public information at no charge, I ask for a fee waiver; if fees would apply, please tell me the estimate before
> processing.
>
> Thank you,
> Nick Soderstrom
> nick@eatsranked.com

Once records arrive: save them under `data/raw/official/dchealth/` (git-ignored) with the date received, read the field list before
counting anything (the playbook's "read the inspection schema" rule), and match by DLCP license number first, then name at the premises
address (`official.py`'s agreement rules). Show the counts and the date as DC Health's record, pass/fail only where a record says it,
and never a grade of ours. A closure without a matching reopening date is not a closure for the app: the place's own live licenses decide.
A crawl of dc.healthinspections.us stays off unless Nick says yes (then one request at a time, cached, stopping at any block).
