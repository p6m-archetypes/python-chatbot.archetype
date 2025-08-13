let context = #{};

context += prompt("Github Organization:", "organization-name", #{
  placeholder: "acme-inc",
  help: "The organization or username where this project will be published",
});

// Create project prefix variations
context += prompt("Project Prefix:", "project-prefix", #{
    placeholder: "Customer Chat",
    help: "Project Name",
    cases: [
        CasedIdentityCasedValue(PROGRAMMING_CASES),
    ],
});

context += prompt("App name:", "app-name", #{
    cases: [
        CasedIdentityCasedValue(PROGRAMMING_CASES),
        FixedKeyCasedValue("ProjectTitle", TitleCase),
    ],
});

context += prompt("Chatbot port:", "chatbot-port", #{
    placeholder: "Customer Chat",
    defaults_with: "8501",
});

if ANSWERS.menus != () {
    for menu in ANSWERS.menus {  // get an array of all the property names via 'keys'
        if menu["select_type"] == "single" {
            context += prompt(menu["menu_name"] + ":", menu["menu_name"], #{
                    help: "Project Features",
                    type: Select(menu["menu_options"] + ["None"]),
                });
        } else {
            context += prompt(menu["menu_name"] + ":", menu["menu_name"], #{
                help: "Project Features",
                type: MultiSelect(menu["menu_options"]),
            });
        }
    }
}

// Create case variations for the combined project prefix and suffix
context += set("project-name", render("{{ project-prefix }}-{{ app-name }}", context), #{
    cases: [
        CasedIdentityCasedValue(PROGRAMMING_CASES),
        FixedKeyCasedValue("ProjectTitle", TitleCase),
    ],
});



// Generate content
render(Directory("content/base"), context,
    #{
        if_exists: Overwrite,
    });

render(Archetype("manifests"), context["project-name"], context +
    #{
        "persistence": "None",
        if_exists: Overwrite,
    }
);
render(Archetype("gitignore"), context["project-name"],
    #{
        "ignore": ["python"],
        if_exists: Overwrite,
    }
);


//
// Publishing
//
if switch_enabled("zip") {
  zip(context["project-name"], render("{{ project-name }}.zip", context));
}
if switch_enabled("tarball") {
  tar_gz(context["project-name"], render("{{ project-name }}.tar.gz", context));
}

if switch_enabled("git-init") || switch_enabled("git-publish") {
  git_init(context["project-name"], "main");
  git_add_all(context["project-name"]);
  git_commit(context["project-name"], "initial commit");
  git_remote_add(context["project-name"], "origin", render("https://github.com/{{ organization-name }}/{{ project-name }}.git", context));

  if switch_enabled("git-publish") {
    gh_repo_create(render("{{ organization-name }}/{{ project-name }}", context), Private);
    git_push(context["project-name"], "origin", "main");
  }
} else {
  display();

  log(Info, "Copy and paste the following commands to publish your project:");

  display();

  display(render("cd {{ project-name }}", context));
  display("git init -b main");
  display(render("gh repo create {{ organization-name }}/{{ project-name }} --private --source=. --remote=origin", context));
  display("git add .");
  display("git commit -m 'initial commit'");
  display("git push -u origin HEAD");
}



