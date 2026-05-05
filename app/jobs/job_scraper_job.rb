class JobScraperJob < ApplicationJob
  queue_as :default

  def perform(job_search)
    # Set the timezone for the job execution
    Time.zone = job_search.timezone

    # Log the start of the job
    Rails.logger.info "Starting job search for: #{job_search.job_title} in #{job_search.location}"

    begin
      # Initialize the scraper with the job search parameters
      scraper = JobScraper.new(
        job_title: job_search.job_title,
        location: job_search.location,
        remote: job_search.remote,
        language_code: job_search.language_code,
        board_relevance: job_search.board_relevance,
        number_of_jobs: job_search.number_of_jobs
      )

      # Perform the scraping
      results = scraper.scrape
    #   results = [
    #   {
    #     :title=>"100% Remote: Opening for Ruby on Rails Software Engineer at San Francisco, CA",
    #     :company_name=>"Jobs via Dice",
    #     :company_website=>nil,
    #     :company_description=>nil,
    #     :url=> "https://www.linkedin.com/jobs/view/100%25-remote-opening-for-ruby-on-rails-software-engineer-at-san-francisco-ca-at-jobs-via-dice-4248992488?",
    #     :description=> "Dice is the leading career destination for tech experts at every stage of their careers. Our client, TechAffinity Inc, is seeking the following. Apply via Dice today!\n\nJob Title : Ruby on Rails Software Engineer\n\nPosition Type: Contract\n\nRemote Work : 100% Remote within Bay Area\n\nLocation: San Francisco, CA - Local only.\n\nMain skills.\n\nAmazon Web Services (AWS),Docker, Ruby\n\nJob Description\n\nOverview: Checkr s current background check solution features several public APIs, both public and internal portals, and a range of microservices.\n\nCheckr hired a team of Python Backend Software Engineers to support a project focusing on the integration between Checkr s services and their partner s data (DMV s, courthouses, etc.).\n\nWe are looking for one more contract Software Engineer to support this team.\n\nThe work would be done in slightly different systems and would require some refactoring of existing code to be able to consume the changes made by the Backend Software Engineers.\n\nLooking for a backend focused Senior Software Engineer (10+ years) with expertise in Ruby on Rail, AWS, and Docker, and a high standard for quality.\n\nResponsibilities:\n\nCollaborate with other engineers and product managers to understand all project requirements.\n\nDeliver performant, reliable, scalable, and secure code.\n\nManage individual project priorities, deadlines and deliverables.\n\nProvide regular updates to teams, stakeholders, and leadership.\n\nQualifications:\n• Overall 12+ years of experience as a Software Engineer\n• 10+ years of experience as a Ruby on Rails Engineer\n• Experience working in Health-Tech or Fintech is a plus\n• Expertise with Ruby on Rails\n• Experience with AWS and Docker\n• Understanding of microservice architecture infrastructure\n• Experience designing and implementing REST APIs\n• A very high standard for quality, compliance, and attention to detail\n• Excellent written and verbal communication skills with the ability to work across technical teams, business stakeholders, and leadership.\n\nInterview Process: Video Round\n\n30 minute with VP of Engineering\n\n30 minute with Engineering Lead and Hiring Manager",
    #     :location=>"Anywhere",
    #     :remote=>nil,
    #     :posted_at=>nil
    #   },
    #   {
    #     :title=>"Immediate Interview-ROR(Ruby on Rails) Architect-REMOTE",
    #     :company_name=>"Parmesoft Inc.",
    #     :company_website=>nil,
    #     :company_description=>nil,
    #     :url=>"https://www.dice.com/job-detail/639d4cd3-ad0c-491c-a158-8397e603081f?",
    #     :description=> "Position: ROR(Ruby on Rails) Architect-REMOTE\n\nLocation: REMOTE\n\nDuration: Long term\n\nJob Description\n• As a hands-on architect, primary responsibilities center around design and development of web based, real-time and batch applications\n• Collaborate with members of the design team both technical as well as business owners to identify requirements and design new products or extensions to existing products.\n• Produce application prototypes with sufficient detail to allow others in the development team to complete the development work.\n• Provide technical oversight to the development process including code reviews and mentoring of the technical team.\n• Must be able to deliver solutions end-to-end with a focus on hitting delivery milestones. Experience in an agile development environment and understanding of agile/lean delivery methods is required.\n• Propose and document technical design recommendations and improvements. Positions in our technical team require strong technical opinions and open communication.\n• Document designs and development work according to established documentation standards\n• Design and oversee unit tests to ensure application logic is fully exercised for each application component.\n\nKey Responsibilities:\n• Develop and maintain robust, scalable, and secure applications using Ruby on Rails for backend and React for frontend.\n• Design and implement RESTful APIs and integrate third-party services.\n• Optimize application performance and troubleshoot/debug production issues.\n• Collaborate with product managers, designers, and other developers to enhance user experience.\n• Follow best practices in CI/CD, testing, and deployment.\n\nQualifications:\n• 3+ years of experience in Ruby on Rails and React.js development.\n• Strong knowledge of PostgreSQL, MySQL, or similar databases.\n• Experience with GraphQL, REST APIs, and cloud platforms (AWS, Azure, or Google Cloud Platform) is a plus.\n• Understanding of Agile methodologies, DevOps, and CI/CD pipelines.\n• Strong problem-solving skills and ability to work in a collaborative, onshore\n\nThanks& Regards\n\nShanu Francis\n\n_____________________\n\nParmesoft Inc.\n\n2626 Cole Ave,Ste:300\n\nDallas, TX. 75204\n\nPhone:\n\nFax:\n\nEmail:",
    #     :location=>"Anywhere",
    #     :remote=>nil,
    #     :posted_at=>nil
    #   },
    #   {
    #     :title=>"Ruby on Rails + Hotwire Frontend Pixel Perfectionist",
    #     :company_name=>"Hellotext",
    #     :company_website=>nil,
    #     :company_description=>nil,
    #     :url=>"https://rubyonremote.com/jobs/67816-ruby-on-rails-hotwire-frontend-pixel-perfectionist-at-hellotext?",
    #     :description=> "Do you obsess over pixel-perfect UI, live and breathe Hotwire and Tailwind, and enjoy squeezing every drop of performance from Rails’ view layer? Join us and own the customer-facing side of Hellotext. You’ll shape how merchants interact with our platform and help set the visual and interaction standards for everything we build.\n\nWhat you’ll do\n• Design & build sleek, responsive interfaces on Ruby on Rails using Hotwire, Stimulus, and Tailwind CSS.\n• Craft reusable components and design systems that keep our UI consistent and easy to extend.\n• Collaborate with product, design, and backend engineers to launch new features fast.\n• Optimize performance, accessibility, and cross-browser behavior.\n• Write clean, maintainable code backed by solid tests and clear documentation.\n• Debug & iterate quickly, balancing polish with pragmatic shipping.\nWhat you bring\n• Proven experience shipping production-grade frontends on Ruby on Rails (Hotwire, Stimulus) or a modern JS framework (Vue, React, etc.).\n• Mastery of HTML5, CSS3, and modern CSS tooling (Tailwind, PostCSS, etc.).\n• Solid JavaScript skills (ES6+) and a good grasp of progressive enhancement.\n• Familiarity with REST or GraphQL APIs and how to consume them gracefully.\n• Comfortable with Git, code reviews, and an agile, remote workflow.\n• A sharp eye for detail paired with a user-centric mindset.\n• Passion for staying current on UI trends, accessibility, and performance best practices.\nNice to Have\n• Experience with eCommerce platforms.\n• Exposure to design systems or component-driven development.\n• Basic knowledge of backend Rails patterns (you’ll interface with our backend team, but deep server-side expertise isn’t required).\nOur Stack\nRuby on Rails, Hotwire, Stimulus, Tailwind CSS, PostgreSQL, ElasticSearch, and GitHub.\n\nYou\nYou love building products from the ground up, influencing design decisions, and seeing users delight in your work. You understand when to polish and when to ship, and you thrive with autonomy—not micromanagement.\n\nBenefits\n• 100 % Remote: work from anywhere, anytime.\n• Flexible schedule: craft a routine that suits your life.\n• Unlimited paid time off: take the rest you need, when you need it.\nReady to craft the front end of the next generation of eCommerce engagement? Apply now and let’s build something remarkable together",
    #     :location=>"Anywhere",
    #     :remote=>nil,
    #     :posted_at=>nil
    #   },
    #  {
    #   :title=>"Mid-Level Full Stack Developer (Ruby on Rails), Remote Job",
    #   :company_name=>"Prevail",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://dynamitejobs.com/company/prevail/remote-job/mid-level-full-stack-developer-ruby-on-rails?",
    #   :description=>
    #    "About Prevail Legal\n\nA well-funded startup founded in San Francisco, our workforce includes a diverse collection of individuals located across the country. Our first-of-its-kind platform combines secure video conferencing with a collection of intuitive tools developed for conducting remote, in-person, and hybrid legal proceedings.\n\nBy maintaining a dynamic work environment where employees collaborate and grow, we aim to modernize and transform the processes involved in court reporting, testimony management, trial preparation, use of video evidence, and more. Join us in disrupting the legal industry and beyond while working alongside our talented team!\nAbout the Position:\n\nWe are seeking a motivated and skilled Mid-Level Full Stack Developer with experience in Ruby on Rails. As a Mid-Level Full Stack Developer, you will contribute to building and maintaining web applications, collaborating with the team to implement new features, and optimizing performance. You will work with both object-oriented and functional programming paradigms in a fully remote environment. Success in this role requires a solid understanding of Git/source control and familiarity with Gen-AI tools and their practical applications in development workflows. This position reports to the Chief Technology Officer.\nRequired Qualifications:\n• 4+ years of Ruby on Rails experience\n• Strong understanding of Git/source control systems\n• Solid understanding of object-oriented and functional programming paradigms\n• Ability to write clear technical documentation\n• Familiarity with Gen-AI tools and their practical applications in development workflows\n\nPreferred Knowledge:\n• Familiarity with WebRTC\n• Experience writing performant JavaScript preferably Stimulus, Hotwire, or Importmaps\n• Understanding of asset optimization techniques\n• Experience with PostgreSQL (1+ year preferred)\n• Exposure to AWS/Kubernetes environments\n\nIdeal Candidate:\n• A passionate self-starter with strong time-management skills\n• Exceptional problem-solving ability and critical thinking\n• Collaborative but capable of working independently\n• Experience working in smaller companies or startups is a plus\n• Interest in mentoring junior developers and growing within the company\n\nBenefits:\n• Comprehensive medical, dental, vision, and 401(k) plans\n• PTO, including vacation and company holidays\n• Generous continuing education allowance\n• Employee stock option plan\n• Remote-first workplace\n• Open, diverse, and respectful work culture\n\nCompensation Range: $120,000 - $160,000 per year. The final base salary will be determined based on several factors, including geographical location, level of experience, relevant skills, and knowledge.\n\nPrevail Legal reserves the right to change this job description to meet the organization's business needs. Please note that the pay band listed is for major cities, and compensation is based on both location and experience.\n\nWe are hiring for US Citizens and do not provide H1B Visa support.\n\nWe are committed to equal employment opportunity regardless of race, color, ancestry, religion, sex, national origin, sexual orientation, age, citizenship, marital status, disability, gender, gender identity or expression, or veteran status. We are proud to be an equal opportunity workplace.",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    # },
    # {
    #   :title=>"Customer Solutions Engineer (Ruby on Rails) - REMOTE IN BRAZIL",
    #   :company_name=>"MyTime",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://www.builtinla.com/job/customer-solutions-engineer-ruby-rails-remote-brazil/4451263?",
    #   :description=> "Company Description\n\nMyTime is a fully integrated scheduling, payments, and automated marketing platform, specializing in large multi-location chains and franchises. Our mission critical software -- which includes in-store scheduling and online booking, client record management, email and SMS marketing, and a full point of sale for handling payments -- is used in every aspect of the customer journey. Our customers rely on their service businesses to remain competitive in the age of Amazon, and they need a next generation POS to help them achieve this growth. We aspire to be the “operating system” of their business.\n\nWe also made it easy to plug our online booking, payments and messaging capabilities into the places customers are found today, including Google Search, Facebook, Instagram, and the merchants’ own websites and mobile apps. Upon adopting MyTime, our customers see average revenue growth of up to 30% through improved operational efficiency, greater customer retention, and access to new customer acquisition channels.\n\nOur product is used at over 14,000 locations across the globe, ranging from single-location sole proprietors to multi-billion dollar Fortune 500 chains. As a completely cloud-based solution, MyTime is designed for quick and easy deployments. It’s lauded for its ease-of-use and short ramp-up time, having won numerous awards such as the Best Commerce Product of 2017 from the Local Search Association.\n\nMyTime is backed by Upfront Ventures and Khosla Ventures and was founded by Ethan Anderson, a successful serial entrepreneur whose first startup, Redbeacon, won TechCrunch50 in 2009 and was acquired by The Home Depot.\n\nCome help us realize our vision of becoming the world’s leading online scheduling and local commerce platform!\n\nJob Description\n\nYou will lead the effort to design and develop data migration tools and processes that enable new customers to go live with MyTime's Point of Sale / Appointment Scheduling / CRM solution. New customers cannot go live on our platform until you’ve completed your work, so this role is vital to the growth of the company.\n\nYou’ll work with the SAAS implementation manager to understand the customer's needs and integration points. You’ll need to be creative and detail oriented as you develop custom approaches to extract, convert and migrate data such as clients, appointments and transactions from legacy systems into MyTime. You'll need to determine when MyTime will be the master and when we will be a client of another system with real-time or asynchronous connections. In some cases, you'll also lead or assist with software development of custom features for the client that are 'must haves' before they can go live.\n\nAs a software engineer, you should be generally passionate about coding and have an interest in building applications with high usability, scalability, and test coverage. In your everyday work, you should continuously contribute to good overall software design with the goal to achieve a highly structured large scale software product. You should also maintain a high awareness of development industry trends and best practices.\n\nIn addition to your passion for coding, you should also want to help in other aspects of building a new company: Designing features, making good product decisions, and building a culture of excellence. We’re seeking engineers who are ready to attack deep technical challenges as well as have an impactful role in product and company development!\n\nKey Responsibilities\n• Execute specific data migration tasks utilizing both manual and scripted processes\n• Develop and maintain web scrapers that can accurately pick up data elements and import them into the right database fields\n• Investigate legacy software products to figure out the best approach for data extraction\n• Implement a migration pipeline between two enterprise systems, likely using a data integration platform and in some cases a continuous syncing solution\n• Create individual data migration jobs to move portions data based on the needs of different customers go-live date\n• Write field-level transformation and validation code to allow data to flow reliably\n• Be responsible for verifying the pipeline is acting predictably: validate at each stage of migration, and generate reconciliation reports\n\nQualifications\n• Should be Brazil-based, and willing to work from home\n• Minimum 2 years of Ruby on Rails\n• Intermediate to expert proficiency with analysis and migration of SQL databases\n• Experience pipelining data in an imperfect environment—retrying through rate limits, http errors, network issues, etc.\n• Experience with agile software development environments\n• Excellent written and verbal communication skills, fluent in English\n\nAdditional Information\n\nThis role provides a competitive salary of $65,000/year and a transparent and exciting startup culture that is singularly focused on empowering people to make an impact in their jobs. The applicant MUST be based in Brazil, must speak English fluently, and be able to collaborate with their Brazilian team members.",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    # },
    # {
    #   :title=>"Senior Ruby on Rails Developer",
    #   :company_name=>"Vistaoutdoor",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://www.ziprecruiter.com/c/Vistaoutdoor/Job/Senior-Ruby-on-Rails-Developer/-in-San-Diego,CA?jid=d07e9acd6950faa5",
    #   :description=> "Job Description\n\nJOB OVERVIEW\n\nRevelyst, the future standalone Outdoor Products company at Vista Outdoor is a collective of makers who design and manufacture performance gear and precision technologies. Our category-defining brands leverage meticulous craftsmanship and cross-collaboration to pursue new innovation and redefine what is humanly possible in the outdoors.\n\nWe are looking for a Sr. Ruby on Rails Developer to join our PinSeeker team on the Precision Sports and Technology platform. PinSeeker runs virtual competitions on golf simulators. In our games, players compete against golfers from around the world to win points, prizes, and cash. We believe it is time for a renaissance in sim golf entertainment. Players expect easy access to golf activities and a suite of compelling games to play on their sim - our mission is to deliver those experiences.\n\nThis position reports to the Vice President of Software Engineering and allows you to work remotely.\n\nAs the Sr. Ruby on Rails Engineer, you will have an opportunity to:\n• Design, develop, and maintain high-quality and scalable features for the PinSeeker application.\n• Work closely with the product team to ensure specifications are being met and value is being provided to our users.\n• Ensure the quality and performance of the application and address any issues that may arise.\n• Write and maintain tests (unit, integration, etc.) to ensure new issues are not introduced into the application and that found issues are correctly resolved.\n• Help guide our technical strategy moving forward including continuous improvement of our processes.\n• Collaborate with teams to estimate and prioritize feature development.\n• Mentor junior developers on best practices and industry standards.\n\nYou have:\n• Bachelor's degree in computer science, engineering, or related field, or equivalent professional experience.\n• Hands-on experience in software development with a minimum of 5 years with Ruby on Rails and its associated technologies (Devise, Redis, Sidekiq, Rails Admin, etc.).\n• Proficient in Postgres including writing and optimizing queries.\n• Familiar with GraphQL and writing performant GraphQL endpoints.\n• Proficient in testing frameworks (RSpec) and advocate for full coverage of all product features.\n• Experience with version control systems such as Git.\n• Familiarity with continuous integration and deployment (CI/CD) pipelines.\n• Excellent problem-solving and analytical skills.\n• Effective communication and collaboration abilities.\n• Driven and self-motivated and can work independently and with your teammates.\n• Focused on continuously sustainably delivering customer value.\n• Bonus points for being a golfer!\n\nMinimum Education Required\n• Bachelors\n\nYears of Experience\n• 5+\n\n#ForesightSports\n\n#LI-BC1\n\nPay Range:\nAnnual Salary: $110,000.00 - $150,000.00\n\nThe actual annual salary offered to a candidate will be based on variables including experience, geographic location, education, and skills/achievements, and will be mutually agreed upon at the time of offer.\n\nWe offer a highly competitive salary, comprehensive benefits including: medical and dental, vision, disability and life insurance, 401K, PTO, paid holidays, gear discounts and the ability to add value to an exciting mission!\n\nOur Postings are not intended for distribution to or use in any jurisdiction, country or territory where such distribution or use would violate local law or would subject us to any regulations in another jurisdiction, country or territory. We reserve the right to limit our Postings in any jurisdiction, country or territory.\n\nEqual Opportunity Employer Minorities/Females/Protected Veteran/Disabled",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    # },
    # {
    #   :title=> "Full-Stack Product Developer 💎 ⚛️ (Ruby on Rails + React)",
    #   :company_name=>"Freshly Commerce",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://weworkremotely.com/listings/freshly-commerce-full-stack-product-developer-ruby-on-rails-react?",
    #   :description=> "At Freshly Commerce, we’re hiring a Full-Stack Developer (Ruby on Rails + React) to help grow our 3 Shopify apps for brands and retailers globally, like Sennheiser, YAMAHA, and Stanley Drinkware. Our apps simplify operational complexities like inventory management, order fulfillment, and perishables traceability.\n\nWe're a small but mighty team, supporting over 20,000 businesses. Bootstrapped and profitable, we're scrappy in our approach to learn and adapt quickly, yet we take great care in the work we deliver.\n\nIf this sounds like the kind of place you'd like to work, we'd love to hear from you!\n\nAbout this role\n\nIn this role, you'll have significant ownership of your work, make impactful decisions daily, and report directly to a senior developer and the founders. This is a full-time remote position open to candidates in all timezones.\n\nYou’ll be responsible for expanding our product offering, finding solutions to things that aren’t working, and solving complex problems in logistics and supply chain. As one of our early product hires, you'll learn the ins and outs of a fast-growing SaaS product.\n\nHere are your daily tasks in this job:\n• Independently manage projects from initial, rough designs to final implementation, including creating task lists in Linear, breaking down PRs into manageable, deployable code segments, testing in staging, deploying to production, and monitoring app performance post-deployment.\n• Prioritize and handle timely dependency upgrades in our applications with the same enthusiasm as greenfield projects, recognizing their importance in maintaining app security and enhancing user experience.\n• Work closely with the technical support team (Tier 2 support) on a weekly basis to prioritize development tasks, address bugs, provide technical guidance on custom implementation projects for some of our larger merchants.\n• Assist our incredible support team (Tier 1 support) with merchant questions in Slack and take pleasure in providing solutions.\n• Effectively communicate your progress and collaborate on problem-solving using digital tools like Slack and GitHub PRs.\n• Rapidly learn and adopt a product development mindset, considering automated tests essential for building confidence in your code.\n• Support your team members and customers whenever needed. As a close-knit team, we thrive when we help each other.\n• Adapt to changing priorities and manage multiple tasks simultaneously.\n• Stay calm under pressure, especially when faced with multiple Rollbar errors, a full Sidekiq queue, or app downtime alerts.\n• Be comfortable working from home, using Slack as our main form of communication.\n\nQualifications\n• 2+ years of experience with Ruby on Rails\n• Experience with React, including hooks and context APIs\n• Experience with Shopify REST and GraphQL APIs is a plus\n• Experience with Shopify CLI and Theme app extension development is a plus\n\nOur stack\n• Ruby on Rails\n• PostgreSQL\n• React\n• Shopify's Polaris design system\n• Redis for caching and background queues\n• Sidekiq for background processing\n• Heroku for application hosting\n\nWho you are\n\nExperience is key in this role. We’d love to know the extent of your experience with Rails and React as a combined tech stack. Can you provide insights into how you've set up Rails and React projects in the past? Are there any specific projects that could serve as a testament to your skills and capabilities?\n\nWe're particularly interested in your experience with Shopify API, Shopify CLI, or GraphQL API. Even if these experiences are not part of your repertoire, we value your expertise with integrations on other platforms. If available, we’d love if you can share any public app or API documentation from those platforms.\n\nBeyond technical expertise, success in this role means embodying these three core values:\n• Resourcefulness: You are relentlessly resourceful, always finding a way to achieve the highest standards of quality. You know where to look and whom to consult when faced with challenges, understanding that we always support each other.\n• Ownership: You take complete ownership and pride in your work. This means deeply understanding our users' problems and how new features or updates affect them.\n• Communication: You effectively communicate your progress, challenges, checklists, and pull requests, detailing them in Linear or GitHub PR descriptions to keep the rest of the team informed. Effective communication is crucial in our fully remote and asynchronous team environment.",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    # },
    # {
    #   :title=>"Customer-Facing Ruby on Rails Developer",
    #   :company_name=>"Labguru",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://www.builtinboston.com/job/customer-facing-ruby-rails-developer/3011451?",
    #   :description=> "Description\n\nWe are looking for a talented Ruby on Rails Developer with strong customer-facing skills to join our R&D team, working at the forefront of life science research platforms.\n\nIf you are passionate about high quality code, software design and modern web technologies your place is with us.\n\nIn this role, you will work closely with an agile team of passionate developers, product managers and application scientists to realize great ideas and create the best ever platform for researchers and laboratories. You will be responsible for working closely with our customers , provide technical support, and ensure the successful implementation and usage of our tool.\n\nIf you are a Ruby on Rails enthusiast with a passion for customer success, we invite you to apply for this exciting opportunity to contribute to the success of both our customers and our dynamic development team.\n\nKey Qualifications/Skills:\n• Excellent interpersonal skills\n• Passionate about delivering solutions and providing excellent service.\n• Be a team player and push your colleagues to excellence.\n• Proven experience as a Ruby on Rails Developer, with a focus on customer-facing roles.\n• Strong proficiency in Ruby programming and the Ruby on Rails framework.\n• Excellent problem-solving skills and the ability to communicate technical concepts to both technical and non-technical audiences.\n\nRequirements\n• A Must - At least 2 years of work experience in web development with a good understanding of backend and frontend aspects in at least one of the following programming languages: Ruby on Rails, Python\n• Experience with at least a few of the following: HTML, CSS, JavaScript , Hotwire, Angular, React, AWS, CI/CD, Git\n• Experience with Docker (advantage)\n• Experience with MySql (advantage)\n• Experience with ElasticSearch (advantage)\n• Experience with version control systems (e.g., Git) and deployment tools. (advantage)\n• Knowledge of cloud platforms such as AWS. (advantage)\n• Understand the dynamic environment of development and share the load with your colleagues.\n• Contribute to the team spirit and pleasant atmosphere that makes our team so special!\n• Willingness and ability to work remotely full time.\n• Willingness to travel to onsite visits occasionally.\n• Excellent English written and verbal communicational skills\n• A MUST - GreenCard holder or US Resident\n• Bachelor's degree in Computer Science or a related field.\n• A degree in Life sciences (huge advantage)\n\nBenefits\n• Remote Model : Flexible work hours from home.",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    # },
    # {
    #   :title=>"Senior Ruby Rails ( ROR) Developer - REMOTE",
    #   :company_name=>"JSM Consulting",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://www.dice.com/job-detail/d4105614-eeb6-4a0d-815b-4bcc890e873a?",
    #   :description=> "• Four year degree in computer science or related field, or equivalent experience\n• Three-plus years experience with Ruby on Rails\n• Agile software development principles, practice and process experience (from use case definition to component delivery) experience required\n• RSpec, git, Capistrano experience preferred\n• Angular, JavaScript, JQuery experience required\n• RDBMS (PostgreSQL, Oracle) required\n• NoSQL (MongoDB, CouchDB) database experience preferred\n• SOA and Web service development experience preferred\n• Experience deploying solutions on Linux platforms preferred\n• RESTful Web service using XML, XSD, JSON experience preferred\n• AMQP or JMS messaging experience preferred\n•",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    # },
    # {
    #   :title=>"Ruby on Rails Engineer",
    #   :company_name=>"EverAI Limited, Nr.",
    #   :company_website=>nil,
    #   :company_description=>nil,
    #   :url=>"https://www.virtualvocations.com/job/ruby-on-rails-engineer-2605733-i.html?",
    #   :description=> "A company is looking for a Ruby on Rails Engineer with extensive frontend expertise.\n\nKey Responsibilities\n• Collaborate with the Product Manager to review project specifications and requirements\n• Prepare integration plans, breakdowns, and estimations for backend and frontend tasks\n• Implement code across backend and frontend, focusing on user-friendly interfaces\n\nRequired Qualifications\n• 3 years of experience as a full-stack or software engineer with extensive frontend development experience\n• Strong expertise in Ruby on Rails, including recent hands-on experience\n• Experience working in tech scale-ups or fast-paced environments\n• Proficiency with frontend technologies such as Stimulus, TurboStreams, TurboFrames, and Hotwire\n• Ownership and commitment to delivering high-quality user experiences",
    #   :location=>"Anywhere",
    #   :remote=>nil,
    #   :posted_at=>nil
    #   }
    # ]

      # Process the results
      results.each do |job_data|
        # Skip if required data is missing
        next if job_data[:company_name].blank? || job_data[:url].blank?

        # Find or create the company
        company = Company.find_or_create_by!(name: job_data[:company_name]) do |c|
          c.description = job_data[:company_description]
        end

        # Create the job post if it doesn't exist
        JobPost.find_or_create_by!(
          title: job_data[:title],
          company: company,
          job_search: job_search,
          website: job_data[:url],
          description: job_data[:description],
          location: job_data[:location],
          remote: job_data[:remote],
          posted_at: job_data[:posted_at]
        )
      end

      # Log successful completion
      Rails.logger.info "Successfully completed job search for: #{job_search.job_title}"
    rescue => e
      # Log any errors that occur during scraping
      Rails.logger.error "Error during job search for #{job_search.job_title}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Re-raise the error to trigger job retry
      raise
    end
  end
end