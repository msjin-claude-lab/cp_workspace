package practice.loan;

/** 대출 회원. */
public class Member {

    private final String id;
    private final String name;
    private final String email;
    private boolean suspended;

    public Member(String id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.suspended = false;
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public boolean isSuspended() {
        return suspended;
    }

    public void setSuspended(boolean suspended) {
        this.suspended = suspended;
    }

    @Override
    public String toString() {
        return "Member{" + id + ", " + name + "}";
    }
}
