# Eko: Project Overview

**Version**: 4.0 (iOS Native)
**Last Updated**: October 12, 2025
**Platform**: Native iOS (Swift + SwiftUI)

---

## 1. What is Eko?

Eko is a mobile application designed to help parents of children ages 6-16 have better, more meaningful conversations with their kids. Through expert-backed guidance, AI-powered conversation practice, and daily skill-building exercises, Eko transforms difficult parenting conversations from anxiety-inducing moments into confident, prepared interactions.

**Core Value Proposition**: Eko moves parents from "I don't know what to say or how to approach this" to "I feel prepared, confident, and ready to have this conversation with my child."

---

## 2. Who is Eko For?

### Primary Users
- **Parents of children ages 6-16** who want to improve communication with their kids
- Parents navigating difficult conversations (body changes, peer pressure, digital life, etc.)
- Parents seeking research-backed, expert guidance for parenting challenges
- Parents who want to build consistent communication skills over time

### User Needs
- **Guidance**: Clear roadmaps for important age-appropriate conversations
- **Confidence**: Safe space to practice difficult conversations before the real thing
- **Expertise**: Access to research-backed parenting advice tailored to their family
- **Consistency**: Daily skill-building to develop better communication habits
- **Support**: On-demand help when facing parenting challenges in real-time

---

## 3. Main Features

Eko delivers its value through eight core features working together to build parenting confidence:

### 3.1. Conversation Playbook Checklist

**Status**: 📋 Planned (Post-MVP)

A structured, age-based curriculum of essential conversations every parent should have with their child.

**Key Capabilities**:
- **Age-Based Roadmaps**: Automatically filtered topics by child's age (6-9, 10-12, 13-16)
- **11 Conversation Categories**: Body & Health, Digital Life, Emotions, Relationships, Safety, Identity, Education, Money, Ethics, Family, and Life Skills
- **3-Stage Preparation Module**:
  - **Stage 1 - Prepare Yourself**: Evidence-based mindset education with research citations to build parent confidence
  - **Stage 2 - Get Your Plan**: Goal-oriented personalization with context selection and reflection questions
  - **Stage 3 - AI Action Plan**: Personalized "Pre-Conversation Briefing" synthesizing all inputs into actionable guidance
- **Progress Tracking**: Clear status management (To Do, Ready to Prep, In Progress, Done, Skipping)
- **Research-Backed Content**: All content backed by peer-reviewed research with scientific citations

**User Value**: Provides parents with a clear roadmap of what conversations to have and when, eliminating the overwhelming question of "Where do I even start?"

---

### 3.2. Lyra - On-Demand AI Parenting Coach

**Status**: 🚧 In Progress (Text MVP → Voice Later)

An empathetic AI assistant providing hyper-personalized, on-demand parenting support through both text chat and real-time voice conversations.

**Key Capabilities**:
- **Intelligent Text Chat**:
  - Natural conversation flow with streaming responses
  - Auto-resume functionality for active conversations
  - Research citations embedded in responses
  - Persistent conversation history
- **Real-Time Voice Mode** (Planned):
  - Ultra-low latency voice conversations via OpenAI Realtime API with WebRTC
  - Natural turn-taking with automatic interruption detection
  - Real-time transcription of both parent and AI speech
  - Seamless switching between text and voice modes
- **Hyper-Personalization**:
  - Deep integration with child profiles (age, dispositions, personality traits)
  - Long-term memory of behavioral themes and effective strategies
  - Context from previous conversations and parent goals
  - Age-appropriate, child-specific guidance
- **Research-Backed Guidance (RAG System)** (Planned):
  - Curated knowledge base of expert parenting research
  - Semantic search for relevant evidence-based content
  - Citations displayed as expandable links
  - Age-filtered content delivery
- **Safety & Crisis Support**:
  - Content moderation and crisis detection
  - Immediate safety resources when needed
  - Professional help recommendations

**User Value**: Offers immediate, personalized support exactly when parents need it most, acting as a trusted expert available 24/7.

**MVP Approach**: Starting with text-only chat to validate core value before adding voice mode complexity.

---

### 3.3. Daily Practice

**Status**: 📋 Planned

Bite-sized, gamified daily parenting scenarios that build communication skills incrementally over time.

**Key Capabilities**:
- **Scenario-Based Learning**: Daily challenges requiring parents to make choices based on recommended strategies
- **4 Practice Types**:
  - **Basic Scenarios**: Real-world parenting situations with multiple response options
  - **Tool Practice**: Learning specific communication techniques
  - **Reflection**: Self-assessment questions to build awareness
  - **Science**: Research-based facts and evidence
- **Age-Band Matching**: Content automatically matched to user's selected child age (6-9, 10-12, 13-16)
- **Daily Progression**: Users advance through a 20+ day curriculum, one practice per day
- **Points & Feedback**: Immediate scoring and specific feedback for each choice
- **Session Management**:
  - Resume in-progress sessions
  - Daily completion tracking
  - Results screen with performance summary

**User Value**: Makes learning parenting skills feel less overwhelming through consistent, engaging, low-stakes practice that builds confidence over time.

---

### 3.4. Practice Simulator

**Status**: 📋 Planned (Post-Voice Lyra)

A voice-based conversation simulator allowing parents to practice difficult conversations with a realistic simulation of their child before the real conversation.

**Planned Capabilities**:
- **Voice-Based Interaction**: Natural voice input with real-time speech recognition
- **Realistic Child Simulation**:
  - AI responses modeled after parent's actual child
  - Age-appropriate language and reactions
  - Personality traits from parent-provided information
  - Voice synthesis that sounds like their child (using voice samples)
- **Natural Conversation Flow**:
  - Ultra-low latency responses
  - Interruption support for natural turn-taking
  - Voice activity detection
- **Actionable Feedback**: Post-simulation analysis highlighting strengths and improvement areas

**User Value**: Provides a safe, realistic space to practice anxiety-inducing conversations, dramatically reducing fear and boosting confidence for real-world interactions.

---

### 3.5. Child Profile & Settings Hub

**Status**: 📋 Planned (Will Stub for Lyra MVP)

Centralized configuration area where parents input and manage details about their child(ren) to personalize the entire app experience.

**Key Capabilities**:
- **Child Profiles**:
  - Name, age, and birthday for automatic age-band calculation
  - Personality disposition traits (talkative, sensitivity, accountability on 1-10 scales)
  - Multiple child support with independent tracking
- **AI Enhancement**: Profile data directly feeds into:
  - Lyra's personalized responses
  - Practice Simulator behavior (when launched)
  - Conversation Playbook age filtering
  - Daily Practice content matching
- **Parenting Goals**: Capture parent's communication style preferences and specific concerns

**User Value**: Ensures all guidance feels tailored and genuinely helpful by making the AI understand each family's unique context.

**MVP Approach**: Will manually insert test child data into database for Lyra testing, build full profile UI later.

---

### 3.6. Post-Conversation Reflection

**Status**: 📋 Planned

Simple feedback loop encouraging parents to reflect on real conversations after they happen.

**Key Capabilities**:
- **Quick Tagging**: Tag conversations as positive, neutral, or challenging
- **Optional Notes**: Add context and observations
- **Progress Log**: Track practiced and real conversations over time
- **Pattern Recognition**: Identify recurring themes and successful strategies

**User Value**: Encourages mindfulness, reinforces learning, and provides visible progress tracking to build confidence over time.

---

### 3.7. Push Notifications & Engagement

**Status**: 📋 Planned

Thoughtful, minimal notifications that support habit formation without being intrusive.

**Key Capabilities**:
- **Daily Practice Reminders**: Gentle nudge to complete daily skill-building
- **Planned Conversation Reminders**: Prompts for conversations user prepared for
- **Smart Timing**: Respects user preferences and quiet hours
- **Contextual Suggestions**: Relevant content based on child's developmental stage

**User Value**: Keeps the app top-of-mind and encourages consistent usage for maximum skill development.

---

### 3.8. Subscription & Payment Flow

**Status**: 📋 Planned (RevenueCat Ready)

Paid subscription model unlocking full feature access.

**Premium Features**:
- Full Conversation Playbook library access
- Unlimited Daily Practice sessions
- Complete Lyra access (text + voice)
- Unlimited Practice Simulator usage (when launched)
- Advanced analytics and insights

**User Value**: Clear value exchange where premium features deliver measurable parenting confidence and skill development.

---

## 4. How Features Work Together

Eko's power comes from how features reinforce each other:
