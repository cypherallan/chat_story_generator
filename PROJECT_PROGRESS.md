# Chat Story Generator Progress

## Completed

Phase 1 - Character Management

Features:
- Create participant
- Firebase Storage avatar upload
- Firestore storage
- Edit participant
- Delete participant
- Search participant
- Cached network images
- Realtime Firestore updates
- Error handling
- Confirmation dialogs

## Next

Phase 2 - Projects

Goal:
Users create chat projects using participants.

Flow:

New Project
↓
Project name
↓
Choose participants
↓
Save

Firestore:

users/{uid}/projects/{projectId}

Fields:
- title
- createdAt
- participants

STEPS FOR PHASE 2:
Step 1 — Create Project Data Structure
We create a new feature:
lib/features/project_management/
Following the same architecture:
project_management/

    data/

        datasources/

        models/

        repositories/


    domain/

        entities/

        repositories/

        usecases/


    presentation/

        cubit/

        pages/

        widgets/
Similar to person_management.

Step 2 — Create Project Entity
We define what a project is.
Example:
Project

id:
abc123

title:
"Ronaldo Interview"

createdAt:
2026-07-27

participants:
[
  Ronaldo ID,
  Reporter ID
]
The entity will contain:
Project {
 String id;
 String title;
 DateTime createdAt;
 List<String> participantIds;
}

Step 3 — Create Firestore Structure
We will move from only:
persons/
   personId
to:
users/

   uid/

      projects/

          projectId/

              title
              createdAt
              participants
Why under users?
Because later:
User A:
projects
   Ronaldo Story
User B:
projects
   Messi Story
They should not see each other's projects.

Step 4 — Create Project Repository Layer
Like we did with persons:
Create:
ProjectFirestoreDataSource
Responsibilities:
get projects
create project
update project
delete project
Then:
ProjectRepository
Then:
UseCases
Example:
CreateProject
GetProjects
DeleteProject

Step 5 — Create Project Cubit
State management:
Similar to:
PersonCubit
We create:
ProjectCubit
States:
ProjectInitial

ProjectLoading

ProjectLoaded

ProjectCreated

ProjectError

Step 6 — Create Projects List Screen
New screen:
Projects
Instead of opening Participants immediately, the user sees:
My Projects


+ New Project


Ronaldo Interview
2 participants


Messi Story
3 participants

Step 7 — Create New Project Flow
When user taps:
+ New Project
Open:
CreateProjectPage
Flow:
Project name

[ Ronaldo Interview ]


Choose participants

☑ Ronaldo
☑ Reporter
☐ Messi


SAVE

Step 8 — Participant Selection UI
Reuse our existing participants.
We don't duplicate data.
Firestore:
persons

person1
person2
person3
Project stores only IDs:
participants:
[
"80dd0568...",
"245a3215..."
]
Why?
Because if Ronaldo's profile picture changes, every project automatically gets the updated Ronaldo.

Step 9 — Save Project
When Save is clicked:
Create:
users/
   uid/
      projects/
          abc123
with:
{
"title":"Ronaldo Interview",

"createdAt":
"timestamp",

"participants":[
"ronaldoId",
"reporterId"
]
}


Phase 3 — Chat Editor ⭐⭐⭐⭐⭐
This is the heart of the app.
Users can
send messages
receive messages
edit messages
reorder messages
delete messages
duplicate messages
insert dates
insert timestamps

Phase 4 — WhatsApp Simulation
This is what makes the app stand out.
Things like
typing...
online
last seen
delivered ✓
read ✓✓
recording voice...
stickers
reactions
images
documents
location
reply messages
forwarded messages
Basically every major WhatsApp interaction.

Phase 5 — Video Engine
This is the biggest feature.
Generate
Conversation

↓

Auto Scroll

↓

Typing animation

↓

Avatar animation

↓

Export

↓

MP4
Everything should feel like a real WhatsApp conversation.


Phase 6 — Export
Users choose
720p
1080p
4K
30 FPS
60 FPS
Portrait videos optimized for social media.

Phase 7 — Drafts
Users can save incomplete projects and continue later.

Phase 8 — Settings
Things like
Dark mode
Chat themes
Wallpapers
Bubble colors
Font size
Export quality
Backup preferences

Phase 9 — Monetization
This is where your app starts earning.
Ideas include:
Premium themes
Premium export quality
No watermark
Extra animations
Cloud backup
AI-generated conversations
Premium participant packs


I'd build:
✅ Emoji picker
✅ Attachment sheet
✅ Camera & gallery image messages
✅ Typing indicator
✅ Online / Last seen
✅ Message ticks animation
✅ Voice notes
🚀 Finally, the ▶ Play Conversation engine

The attachments in order:
Row 1: Gallery, Camera, Location, contact
row 2: Document, Poll, Event, AI images